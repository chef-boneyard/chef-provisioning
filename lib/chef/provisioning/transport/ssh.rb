require 'chef/provisioning/transport'
require 'chef/log'
require 'uri'
require 'socket'
require 'timeout'
require 'net/ssh'
require 'net/scp'
require 'net/ssh/gateway'

class Chef
module Provisioning
  class Transport
    class SSH < Chef::Provisioning::Transport
      #
      # Create a new SSH transport.
      #
      # == Arguments
      #
      # - host: the host to connect to, e.g. '145.14.51.45'
      # - username: the username to connect with
      # - ssh_options: a list of options to Net::SSH.start
      # - options: a hash of options for the transport itself, including:
      #   - :prefix: a prefix to send before each command (e.g. "sudo ")
      #   - :ssh_pty_enable: set to false to disable pty (some instances don't
      #     support this, most do)
      #   - :ssh_gateway: the gateway to use, e.g. "jkeiser@145.14.51.45:222".
      #     nil (the default) means no gateway. If the username is omitted,
      #     then the default username is used instead (i.e. the user running
      #     chef, or the username configured in .ssh/config).
      # - global_config: an options hash that looks suspiciously similar to
      #   Chef::Config, containing at least the key :log_level.
      #
      # The options are used in
      #   Net::SSH.start(host, username, ssh_options)

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

      # TODO why does #read_file download it to the target host?
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
          begin
            execute("mv #{remote_tempfile} #{path}").error!
          rescue
            # Clean up if we were unable to move
            execute("rm #{remote_tempfile}").error!
          end
        else
          Chef::Log.debug("Uploading #{local_path} to #{path} on #{username}@#{host}")
          Net::SCP.new(session).upload!(local_path, path)
        end
      end

      def make_url_available_to_remote(local_url)
        uri = URI(local_url)
        if is_local_machine(uri.host)
          port, host = forward_port(uri.port, uri.host, uri.port, 'localhost')
          if !port
            # Try harder if the port is already taken
            port, host = forward_port(uri.port, uri.host, 0, 'localhost')
            if !port
              raise "Error forwarding port: could not forward #{uri.port} or 0"
            end
          end
          uri.host = host
          uri.port = port
        end
        Chef::Log.info("Port forwarded: local URL #{local_url} is available to #{self.host} as #{uri.to_s} for the duration of this SSH connection.")
        uri.to_s
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
      rescue Timeout::Error, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EHOSTDOWN, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::ECONNRESET, Net::SSH::Disconnect
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
          Chef::Log.debug("Opening SSH connection to #{username}@#{host} with options #{ssh_start_opts.dup.tap {
                              |ssh| ssh.delete(:key_data) }.inspect}")
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
        if options[:prefix]
          # Make a tempfile on the other side, upload to that, and sudo mv / chown / etc.
          remote_tempfile = "/tmp/#{File.basename(path)}.#{Random.rand(2**32)}"
          Chef::Log.debug("Downloading #{path} from #{remote_tempfile} to #{local_path} on #{username}@#{host}")
          begin
            execute("cp #{path} #{remote_tempfile}").error!
            execute("chown #{username} #{remote_tempfile}").error!
            do_download remote_tempfile, local_path
          rescue => e
              Chef::Log.error "Unable to download #{path} to #{remote_tempfile} on #{username}@#{host} -- #{e}"
              nil
          ensure
            # Clean up afterwards
            begin
              execute("rm #{remote_tempfile}").error!
            rescue => e
              Chef::Log.warn "Unable to clean up #{remote_tempfile} on #{username}@#{host} -- #{e}"
            end
          end
        else
          do_download path, local_path
        end
      end

      def do_download(path, local_path)
        channel = Net::SCP.new(session).download(path, local_path)
        begin
          channel.wait
          Chef::Log.debug "SCP completed for: #{path} to #{local_path}"
        rescue Net::SCP::Error => e
          Chef::Log.error "Error with SCP: #{e}"
          # TODO we need a way to distinguish between "directory or file does not exist" and "SCP did not finish successfully"
          nil
        ensure
          # ensure the channel is closed
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
        gw_user, gw_host = options[:ssh_gateway].split('@')
        # If we didn't have an '@' in the above, then the value is actually
        # the hostname, not the username.
        gw_host, gw_user = gw_user, gw_host if gw_host.nil?
        gw_host, gw_port = gw_host.split(':')

        ssh_start_opts = { timeout:10 }.merge(ssh_options)
        ssh_start_opts[:port] = gw_port || 22

        Chef::Log.debug("Opening SSH gateway to #{gw_user}@#{gw_host} with options #{ssh_start_opts.dup.tap {
                            |ssh| ssh.delete(:key_data) }.inspect}")
        begin
          Net::SSH::Gateway.new(gw_host, gw_user, ssh_start_opts)
        rescue Errno::ETIMEDOUT
          Chef::Log.debug("Timed out connecting to gateway: #{$!}")
          raise InitialConnectTimeout.new($!)
        end
      end

      def is_local_machine(host)
        local_addrs = Socket.ip_address_list
        host_addrs = Addrinfo.getaddrinfo(host, nil)
        local_addrs.any? do |local_addr|
          host_addrs.any? do |host_addr|
            local_addr.ip_address == host_addr.ip_address
          end
        end
      end

      # Forwards a port over the connection, and returns the
      def forward_port(local_port, local_host, remote_port, remote_host)
        # This bit is from the documentation.
        if session.forward.respond_to?(:active_remote_destinations)
          # active_remote_destinations tells us exactly what remotes the current
          # ssh session is *actually* tracking.  If multiple people share this
          # session and set up their own remotes, this will prevent us from
          # overwriting them.

          actual_remote_port, actual_remote_host = session.forward.active_remote_destinations[[local_port, local_host]]
          if !actual_remote_port
            Chef::Log.debug("Forwarding local server #{local_host}:#{local_port} to #{username}@#{self.host}")

            session.forward.remote(local_port, local_host, remote_port, remote_host) do |new_remote_port, new_remote_host|
							actual_remote_host = new_remote_host
              actual_remote_port = new_remote_port || :error
              :no_exception # I'll take care of it myself, thanks
            end
            # Kick SSH until we get a response
            session.loop { !actual_remote_port }
            if actual_remote_port == :error
              return nil
            end
          end
          [ actual_remote_port, actual_remote_host ]
        else
          # If active_remote_destinations isn't on net-ssh, we stash our own list
          # of ports *we* have forwarded on the connection, and hope that we are
          # right.
          # TODO let's remove this when net-ssh 2.9.2 is old enough, and
          # bump the required net-ssh version.

          @forwarded_ports ||= {}
          remote_port, remote_host = @forwarded_ports[[local_port, local_host]]
          if !remote_port
            Chef::Log.debug("Forwarding local server #{local_host}:#{local_port} to #{username}@#{self.host}")
            old_active_remotes = session.forward.active_remotes
            session.forward.remote(local_port, local_host, local_port)
            session.loop { !(session.forward.active_remotes.length > old_active_remotes.length) }
            remote_port, remote_host = (session.forward.active_remotes - old_active_remotes).first
            @forwarded_ports[[local_port, local_host]] = [ remote_port, remote_host ]
          end
          [ remote_port, remote_host ]
        end
      end
    end
  end
end
end
