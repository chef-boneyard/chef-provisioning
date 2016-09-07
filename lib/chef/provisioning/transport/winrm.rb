require 'chef/provisioning/transport'
require 'base64'
require 'timeout'

class Chef
module Provisioning
  class Transport
    # Transport to handle the WinRM connection protocol.
    class WinRM < Chef::Provisioning::Transport
      #
      # Create a new WinRM transport.
      #
      # == Arguments
      # - endpoint: the WinRM endpoint, e.g. http://145.14.51.45:5985/wsman.
      # - type: the connection type, e.g. :plaintext.
      # - options: options hash, including both WinRM options and transport options.
      #   For transport options, see the Transport.options definition.  WinRM
      #   options include :user, :pass, :disable_sspi => true, among others.
      # - global_config: an options hash that looks suspiciously similar to
      #   Chef::Config, containing at least the key :log_level.
      #
      # The actual connection is made as ::WinRM::WinRMWebService.new(endpoint, type, options)
      #
      def initialize(endpoint, type, options, global_config)
        @options = options
        @options[:endpoint] = endpoint
        @options[:transport] = type

        # WinRM v2 switched from :pass to :password
        # we accept either to avoid having to update every driver
        @options[:password] = @options[:password] || @options[:pass]
        
        @config = global_config
      end

      attr_reader :options
      attr_reader :config

      def execute(command, execute_options = {})
        output = with_execute_timeout(execute_options) do
          block = Proc.new { |stdout, stderr| stream_chunk(execute_options, stdout, stderr) }
          session.run(command, &block)
        end
        WinRMResult.new(command, execute_options, config, output)
      end

      def read_file(path)
        result = execute("[Convert]::ToBase64String((Get-Content #{escape(path)} -Encoding byte -ReadCount 0))")
        if result.exitstatus == 0
          Base64.decode64(result.stdout)
        else
          nil
        end
      end

      def write_file(path, content)
        file = Tempfile.new('provisioning-upload')
        begin
           file.write(content)
           file.close
           file_transporter.upload(file.path, path)
        ensure
           file.unlink
        end
      end

      def disconnect
        #
      end

      def escape(string)
        "\"#{string.gsub("\"", "`\"")}\""
      end

      def available?
        # If you can't pwd within 10 seconds, you can't pwd
        execute('pwd', :timeout => 10)
        true
      rescue ::WinRM::WinRMAuthorizationError
        Chef::Log.debug("unavailable: winrm authentication error: #{$!.inspect} ")
        disconnect
        false
      rescue Timeout::Error, Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::ECONNRESET, ::WinRM::WinRMError
        Chef::Log.debug("unavailable: network connection failed or broke: #{$!.inspect}")
        disconnect
        false
      end

      def make_url_available_to_remote(local_url)
        uri = URI(local_url)
        uri.scheme = 'http' if uri.scheme == 'chefzero' && uri.host == 'localhost'
        host = Socket.getaddrinfo(uri.host, uri.scheme, nil, :STREAM)[0][3]
        if host == '127.0.0.1' || host == '::1'
          raise 'Unable to converge locally via winrm. Local converge is currently only supported with SSH. You may only converge with winrm against a chef-server.'
        end
        local_url
      end

      protected

      def session
        @session ||= begin
          require 'winrm'
          ::WinRM::Connection.new(options).shell(:powershell)
        end
      end

      def file_transporter
        @file_transporter ||= begin
          require 'winrm-fs'
          ::WinRM::FS::Core::FileTransporter.new(session)
        end
      end

      class WinRMResult
        def initialize(command, options, config, output)
          @command = command
          @options = options
          @config = config
          @exitstatus = output.exitcode
          @stdout = output.stdout
          @stderr = output.stderr
        end

        attr_reader :stdout
        attr_reader :stderr
        attr_reader :exitstatus
        attr_reader :command
        attr_reader :options
        attr_reader :config

        def error!
          if exitstatus != 0
            msg = "Error: command '#{command}' exited with code #{exitstatus}.\n"
            msg << "STDOUT: #{stdout}" if !options[:stream] && !options[:stream_stdout] && config[:log_level] != :debug
            msg << "STDERR: #{stderr}" if !options[:stream] && !options[:stream_stderr] && config[:log_level] != :debug
            raise msg
          end
        end
      end
    end
  end
end
end
