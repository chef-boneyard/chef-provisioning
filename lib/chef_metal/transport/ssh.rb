require 'chef_metal/transport'
require 'uri'
require 'socket'
require 'timeout'
require 'net/ssh'
require 'net/scp'
require 'net/ssh/gateway'

module ChefMetal
  class Transport
    class SSH < ChefMetal::Transport
      def initialize(host, username, ssh_options, options, global_config)
        @host = host
        @username = username
        @ssh_options = ssh_options
        @options = options
        @config = global_config
      end

      attr_reader :host
      attr_reader :username
      attr_reader :ssh_options
      attr_reader :options
      attr_reader :config

      def execute(command, execute_options = {})
        Chef::Log.info("Executing #{options[:prefix]}#{command} on #{username}@#{host}")
        stdout = ''
        stderr = ''
        exitstatus = nil
        session # grab session outside timeout, it has its own timeout
        with_execute_timeout(execute_options) do
          channel = session.open_channel do |channel|
            # Enable PTY unless otherwise specified, some instances require this
            unless options[:ssh_pty_enable] == false
              channel.request_pty do |chan, success|
                 raise "could not get pty" if !success && options[:ssh_pty_enable]
              end
            end

            channel.exec("#{options[:prefix]}#{command}") do |ch, success|
              raise "could not execute command: #{command.inspect}" unless success

              channel.on_data do |ch2, data|
                stdout << data
                stream_chunk(execute_options, data, nil)
              end

              channel.on_extended_data do |ch2, type, data|
                stderr << data
                stream_chunk(execute_options, nil, data)
              end

              channel.on_request "exit-status" do |ch, data|
                exitstatus = data.read_long
              end
            end
          end

          channel.wait
        end

        Chef::Log.info("Completed #{command} on #{username}@#{host}: exit status #{exitstatus}")
        Chef::Log.debug("Stdout was:\n#{stdout}") if stdout != '' && !options[:stream] && !options[:stream_stdout] && config[:log_level] != :debug
        Chef::Log.info("Stderr was:\n#{stderr}") if stderr != '' && !options[:stream] && !options[:stream_stderr] && config[:log_level] != :debug
        SSHResult.new(command, execute_options, stdout, stderr, exitstatus)
      end

      def read_file(path)
        Chef::Log.debug("Reading file #{path} from #{username}@#{host}")
        result = StringIO.new
        download(path, result)
        result.string
      end

      def download_file(path, local_path)
        Chef::Log.debug("Downloading file #{path} from #{username}@#{host} to local #{local_path}")
        download(path, local_path)
      end

      def write_file(path, content)
        execute("mkdir -p #{File.dirname(path)}").error!
        if options[:prefix]
          # Make a tempfile on the other side, upload to that, and sudo mv / chown / etc.
          remote_tempfile = "/tmp/#{File.basename(path)}.#{Random.rand(2**32)}"
          Chef::Log.debug("Writing #{content.length} bytes to #{remote_tempfile} on #{username}@#{host}")
          Net::SCP.new(session).upload!(StringIO.new(content), remote_tempfile)
          execute("mv #{remote_tempfile} #{path}").error!
        else
          Chef::Log.debug("Writing #{content.length} bytes to #{path} on #{username}@#{host}")
          Net::SCP.new(session).upload!(StringIO.new(content), path)
        end
      end

      def upload_file(local_path, path)
        execute("mkdir -p #{File.dirname(path)}").error!
        if options[:prefix]
          # Make a tempfile on the other side, upload to that, and sudo mv / chown / etc.
          remote_tempfile = "/tmp/#{File.basename(path)}.#{Random.rand(2**32)}"
          Chef::Log.debug("Uploading #{local_path} to #{remote_tempfile} on #{username}@#{host}")
          Net::SCP.new(session).upload!(local_path, remote_tempfile)
          execute("mv #{remote_tempfile} #{path}").error!
        else
          Chef::Log.debug("Uploading #{local_path} to #{path} on #{username}@#{host}")
          Net::SCP.new(session).upload!(local_path, path)
        end
      end

      def make_url_available_to_remote(local_url)
        uri = URI(local_url)
        host = Socket.getaddrinfo(uri.host, uri.scheme, nil, :STREAM)[0][3]
        if host == '127.0.0.1' || host == '::1'
          unless session.forward.active_remotes.any? { |port, bind| port == uri.port && bind == uri.host }
            Chef::Log.debug("Forwarding local server #{uri.host}:#{uri.port} to port #{uri.port} on #{username}@#{self.host}")
            session.forward.remote(uri.port, uri.host, uri.port)
          end
        end
        local_url
      end

      def disconnect
        if @session
          begin
            Chef::Log.debug("Closing SSH session on #{username}@#{host}")
            @session.close
          rescue
          ensure
            @session = nil
          end
        end
      end

      def available?
        # If you can't pwd within 10 seconds, you can't pwd
        execute('pwd', :timeout => 10)
        true
      rescue Timeout::Error, Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::ECONNRESET, Net::SSH::Disconnect
        Chef::Log.debug("#{username}@#{host} unavailable: network connection failed or broke: #{$!.inspect}")
        disconnect
        false
      rescue Net::SSH::AuthenticationFailed, Net::SSH::HostKeyMismatch
        Chef::Log.debug("#{username}@#{host} unavailable: SSH authentication error: #{$!.inspect} ")
        disconnect
        false
      end

      protected

      def session
        @session ||= begin
          ssh_start_opts = { timeout:10 }.merge(ssh_options)
          Chef::Log.debug("Opening SSH connection to #{username}@#{host} with options #{ssh_start_opts.inspect}")
          # Small initial connection timeout (10s) to help us fail faster when server is just dead
          begin
            if gateway? then gateway.ssh(host, username, ssh_start_opts)
            else Net::SSH.start(host, username, ssh_start_opts)
            end
          rescue Timeout::Error
            Chef::Log.debug("Timed out connecting to SSH: #{$!}")
            raise InitialConnectTimeout.new($!)
          end
        end
      end

      def download(path, local_path)
        channel = Net::SCP.new(session).download(path, local_path)
        begin
          channel.wait
        rescue Net::SCP::Error => e
          # TODO we need a way to distinguish between "directory of file does not exist" and "SCP did not finish successfully"
          nil
        # ensure the channel is closed when a rescue happens above
        ensure
          channel.close
          channel.wait
        end
        nil
      end

      class SSHResult
        def initialize(command, options, stdout, stderr, exitstatus)
          @command = command
          @options = options
          @stdout = stdout
          @stderr = stderr
          @exitstatus = exitstatus
        end

        attr_reader :command
        attr_reader :options
        attr_reader :stdout
        attr_reader :stderr
        attr_reader :exitstatus

        def error!
          if exitstatus != 0
            # TODO stdout/stderr is already printed at info/debug level.  Let's not print it twice, it's a lot.
            msg = "Error: command '#{command}' exited with code #{exitstatus}.\n"
            raise msg
          end
        end
      end

      class InitialConnectTimeout < Timeout::Error
        def initialize(original_error)
          super(original_error.message)
          @original_error = original_error
        end

        attr_reader :original_error
      end

      private

      def gateway?
        options.key?(:ssh_gateway) and ! options[:ssh_gateway].nil?
      end

      def gateway
        gw_host, gw_user = options[:ssh_gateway].split('@').reverse
        gw_host, gw_port = gw_host.split(':')
        gw_user = ssh_options[:ssh_username] unless gw_user

        ssh_start_opts = { timeout:10 }.merge(ssh_options)
        ssh_start_opts[:port] = gw_port || 22

        Chef::Log.debug("Opening SSH gateway to #{gw_user}@#{gw_host} with options #{ssh_start_opts.inspect}")
        begin
          Net::SSH::Gateway.new(gw_host, gw_user, ssh_start_opts)
        rescue Errno::ETIMEDOUT
          Chef::Log.debug("Timed out connecting to gateway: #{$!}")
          raise InitialConnectTimeout.new($!)
        end
      end
    end
  end
end
