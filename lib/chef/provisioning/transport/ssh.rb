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
        @using_session = 0
        @session_thread_errors = []
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
        # grab session outside timeout, it has its own timeout
        with_session do |session|
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
        with_session do |session|
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
      end

      def make_url_available_to_remote(local_url, bind_to: 'localhost')
        uri = URI(local_url)
        if is_local_machine(uri.host)
          port, host = forward_remote_port(uri.port, uri.host, uri.port, bind_to)
          if !port
            # Try harder--see if we can get any other ports--if the given port
            # is already taken.  The reason we don't just do this first is, some
            # versions of SSH have bugs where they don't report the actual
            # bound port back to you if you use port 0 (any port mode).
            port, host = forward_remote_port(uri.port, uri.host, 0, bind_to)
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

      def make_remote_url_available_locally(remote_url, bind_to: 'localhost')
        uri = URI(remote_url)
        if is_remote_machine(uri.host)
          # First we try to get the same port, if it's available--easier to read
          # things that way.
          port, host = forward_local_port(uri.port, bind_to, uri.port, uri.host)
          if !port
            port, host = forward_local_port(0, bind_to, uri.port, uri.host)
            if !port
              raise "Error forwarding port: could not forward #{uri.port} or 0"
            end
          end
          uri.host = host
          uri.port = port
        end
        Chef::Log.info("Port forwarded: remote URL #{remote_url} on #{self.username}@#{self.host} is available locally as #{uri.to_s} for the duration of this SSH connection.")
        uri.to_s
      end


      def disconnect
        if @session_thread
          @session_thread.kill
          @session_thread = nil
        end
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
          ssh_start_opts = { timeout:10, logger: Chef::Log.logger, verbose: log_level }.merge(ssh_options)
          Chef::Log.debug("Opening SSH connection to #{username}@#{host} with options #{ssh_start_opts.dup.tap {
                              |ssh| ssh.delete(:key_data) }.inspect}")
          # Small initial connection timeout (10s) to help us fail faster when server is just dead
          session = nil
          begin
            if gateway?
              session = gateway.ssh(host, username, ssh_start_opts)
            else
              session = Net::SSH.start(host, username, ssh_start_opts)
            end
          rescue Timeout::Error
            Chef::Log.debug("Timed out connecting to SSH: #{$!}")
            raise InitialConnectTimeout.new($!)
          end
          @session_mutex ||= Mutex.new
          @session_thread ||= Thread.new do
            while @session
              # If others are doing SSH things, we let them handle processing; this
              # increases the chances they will receive appropriate exceptions.
              if @using_session == 0
                @session_mutex.synchronize do
                  begin
                    # If there was something to process, keep processing
                    next if @session.process?(0)
                  rescue
                    # If there is an error, we save it off so that a real thread can capture it.
                    @session_thread_errors << $!
                    next
                  end
                end
                sleep(0.1)
              end
            end
          end
          session
        end
      end

      #
      # Tell the transport that we are going to do SSH things; this pauses the
      # main loop thread that is pushing SSH forward in the background, so that
      # any SSH errors will be raised by the current thread.  It ain't perfect,
      # but as long as only one SSH thing is actually happening, it will do the
      # errors right.
      #
      def with_session(&block)
        raise_unhandled_errors
        session
        puts "with_session! #{caller[0]}"
        @using_session += 1
        @session_mutex.synchronize do
          puts "in session! #{caller[0]}"
          begin
            block.call(session)
          ensure
            @using_session -= 1
            puts "Done session! #{caller[0]}"
          end
        end
      end

      class UnhandledSSHError < StandardError
        def initialize(original_error)
          @original_error = original_error
        end

        attr_reader :original_error

        def message
          original_error.message
        end
      end

      def raise_unhandled_errors
        if !@session_thread_errors.empty?
          error = @session_thread_errors.shift
          Chef::Log.debug("SSH error caught: #{error.backtrace}")
          raise UnhandledSSHError.new(error)
        end
      end

      # :debug is REALLY terribly verbose and almost never of interest.  If we
      # want verbose, we need to give Chef a new log level like :firehose
      # TODO log_level :firehose
      def log_level
        case Chef::Log.level
        when :info
          :warn
        when :debug
          :info
        else
          Chef::Log.level
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
              Chef::Log.error "Unable to download #{path} to #{local_path} on #{username}@#{host} -- #{e}"
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
        with_session do |session|
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

      def is_remote_machine(host)
        remote_addrs = Addrinfo.getaddrinfo(host, nil) + Addrinfo.getaddrinfo('localhost', nil)
        host_addrs = Addrinfo.getaddrinfo(host, nil)
        remote_addrs.any? do |remote_addr|
          host_addrs.any? do |host_addr|
            remote_addr.ip_address == host_addr.ip_address
          end
        end
      end

      # Forwards packets from remote clients to a local server.
      def forward_remote_port(local_port, local_host, remote_port, remote_host)
        with_session do |session|
          # This bit is from the documentation.
          if session.forward.respond_to?(:active_remote_destinations)
            # active_remote_destinations tells us exactly what remotes the current
            # ssh session is *actually* tracking.  If multiple people share this
            # session and set up their own remotes, this will prevent us from
            # overwriting them.
            actual_remote_port, actual_remote_host = session.forward.active_remote_destinations[[local_port, local_host]]

            if !actual_remote_port
              Chef::Log.debug("Forwarding #{remote_host}:#{remote_port} on #{username}@#{self.host} to local server #{local_host}:#{local_port}")

              session.forward.remote(local_port, local_host, remote_port, remote_host) do |new_remote_port, new_remote_host|
    						actual_remote_host = new_remote_host
                actual_remote_port = new_remote_port || :error
                :no_exception # I'll take care of it myself, thanks
              end
              # Kick SSH until we get a response
              session.loop(0.1) { !actual_remote_port }
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

            @forwarded_remote_ports ||= {}
            actual_remote_port, actual_remote_host = @forwarded_remote_ports[[local_port, local_host]]
            if !actual_remote_port
              Chef::Log.debug("Forwarding #{remote_host}:#{remote_port} on #{username}@#{self.host} to local server #{local_host}:#{local_port}")
              old_active_remotes = session.forward.active_remotes
              session.forward.remote(local_port, local_host, remote_port, remote_host)
              session.loop { !(session.forward.active_remotes.length > old_active_remotes.length) }
              actual_remote_port, actual_remote_host = (session.forward.active_remotes - old_active_remotes).first
              @forwarded_remote_ports[[local_port, local_host]] = [ actual_remote_port, actual_remote_host ]
            end
            [ actual_remote_port, actual_remote_host ]
          end
        end
      end

      # Forwards packets from local clients to a remote server.
      def forward_local_port(local_port, local_host, remote_port, remote_host)
        with_session do |session|
          # This bit is from the documentation.
          if session.forward.respond_to?(:active_local_destinations)
            # active_local_destinations tells us exactly what locals the current
            # ssh session is *actually* tracking.  If multiple people share this
            # session and set up their own locals, this will prevent us from
            # overwriting them.

            actual_local_port, actual_local_host = session.forward.active_local_destinations[[local_port, local_host]]
          else
            # If active_local_destinations isn't on net-ssh, we stash our own list
            # of ports *we* have forwarded on the connection, and hope that we are
            # right.
            # TODO let's remove this when net-ssh 2.9.2 is old enough, and
            # bump the required net-ssh version.
            @forwarded_remote_ports ||= {}
            actual_local_port, actual_local_host = @forwarded_remote_ports[[remote_port, remote_host]]
          end

          if !actual_local_port
            Chef::Log.debug("Forwarding #{local_host}:#{local_port} to remote server #{remote_host}:#{remote_port} on #{username}@#{self.host}")
            actual_local_host = local_host
            actual_local_port = session.forward.local(local_port, local_host, remote_port, remote_host)
            @forwarded_remote_ports[[remote_port, remote_host]] = [ actual_local_port, actual_local_host ] if @forwarded_remote_ports
            Chef::Log.info("Forwarded #{actual_local_host}:#{actual_local_port} to remote server #{remote_host}:#{remote_port} on #{username}@#{self.host}")
          end
          [ actual_local_port, actual_local_host ]
        end
      end
    end
  end
end
end

# I feel so bad about this.  But we need some way to coordinate our loops.
if !Net::SSH::Connection::Session.method_defined?(:process?)
  class Net::SSH::Connection::Session
    def process?(wait=nil)
      return false unless preprocess

      r = listeners.keys
      w = r.select { |w2| w2.respond_to?(:pending_write?) && w2.pending_write? }
      readers, writers, = Net::SSH::Compat.io_select(r, w, nil, io_select_wait(wait))

      postprocess(readers, writers)
      return !(Array(readers).empty? && Array(writers).empty?)
    end
  end
end
