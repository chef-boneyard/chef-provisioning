require 'chef_metal/transport'

module ChefMetal
  class Transport
    class SSH < Transport
      def initialize(host, username, ssh_options, options)
        require 'net/ssh'
        require 'net/scp'
        @host = host
        @username = username
        @ssh_options = ssh_options
        @options = options
      end

      attr_reader :host
      attr_reader :username
      attr_reader :ssh_options
      attr_reader :options

      def execute(command)
        Chef::Log.info("Executing #{command} on #{username}@#{host}")
        stdout = ''
        stderr = ''
        exitstatus = nil
        channel = session.open_channel do |channel|
          channel.request_pty do |chan, success|
            raise "Could not obtain pty" unless success
          end

          channel.exec("#{options[:prefix]}#{command}") do |ch, success|
            raise "could not execute command: #{command.inspect}" unless success

            channel.on_data do |ch2, data|
              stdout << data
            end

            channel.on_extended_data do |ch2, type, data|
              stderr << data
            end

            channel.on_request "exit-status" do |ch, data|
              exitstatus = data.read_long
            end
          end
        end

        channel.wait

        Chef::Log.info("Completed #{command} on #{username}@#{host}: exit status #{exitstatus}")
        Chef::Log.debug("Stdout was:\n#{stdout}") if stdout != ''
        Chef::Log.info("Stderr was:\n#{stderr}") if stderr != ''
        SSHResult.new(stdout, stderr, exitstatus)
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
        if options[:prefix]
          # Make a tempfile on the other side, upload to that, and sudo mv / chown / etc.
          remote_tempfile = "/tmp/#{File.basename(path)}.#{Random.rand(2**32)}"
          Chef::Log.debug("Writing #{content.length} bytes to #{remote_tempfile} on #{username}@#{host}")
          Net::SCP.new(session).upload!(StringIO.new(content), remote_tempfile)
          execute("mv #{remote_tempfile} #{path}")
        else
          Chef::Log.debug("Writing #{content.length} bytes to #{path} on #{username}@#{host}")
          Net::SCP.new(session).upload!(StringIO.new(content), path)
        end
      end

      def upload_file(local_path, path)
        if options[:prefix]
          # Make a tempfile on the other side, upload to that, and sudo mv / chown / etc.
          remote_tempfile = "/tmp/#{File.basename(path)}.#{Random.rand(2**32)}"
          Chef::Log.debug("Uploading #{local_path} to #{remote_tempfile} on #{username}@#{host}")
          Net::SCP.new(session).upload!(local_path, remote_tempfile)
          execute("mv #{remote_tempfile} #{path}")
        else
          Chef::Log.debug("Uploading #{local_path} to #{path} on #{username}@#{host}")
          Net::SCP.new(session).upload!(local_path, path)
        end
      end

      def forward_remote_port_to_local(remote_port, local_port)
        # TODO IPv6
        Chef::Log.debug("Forwarding local server 127.0.0.1:#{local_port} to port #{remote_port} on #{username}@#{host}")
        session.forward.remote(local_port, "127.0.0.1", remote_port)
      end

      def disconnect
        if @session
          begin
            Chef::Log.debug("Closing SSH session on #{username}@#{host}")
            @session.close
          rescue
          end
          @session = nil
        end
      end

      def available?
        execute('pwd')
        true
      rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::ECONNRESET, Net::SSH::AuthenticationFailed, Net::SSH::Disconnect, Net::SSH::HostKeyMismatch
        Chef::Log.debug("#{username}@#{host} unavailable: could not execute 'pwd' on #{host}: #{$!.inspect}")
        false
      end

      protected

      def session
        @session ||= begin
          Chef::Log.debug("Opening SSH connection to #{username}@#{host} with options #{ssh_options.inspect}")
          Net::SSH.start(host, username, ssh_options)
        end
      end

      def download(path, local_path)
        channel = Net::SCP.new(session).download(path, local_path)
        begin
          channel.wait
        rescue Net::SCP::Error
          nil
        rescue
          # This works around https://github.com/net-ssh/net-scp/pull/10 until a new net-scp is merged.
          begin
            channel.close
            channel.wait
          rescue Net::SCP::Error
            nil
          end
        end
      end

      class SSHResult
        def initialize(stdout, stderr, exitstatus)
          @stdout = stdout
          @stderr = stderr
          @exitstatus = exitstatus
        end

        attr_reader :stdout
        attr_reader :stderr
        attr_reader :exitstatus

        def error!
          raise "Error: code #{exitstatus}.\nSTDOUT:#{stdout}\nSTDERR:#{stderr}" if exitstatus != 0
        end
      end
    end
  end
end
