require 'chef_metal/transport'
require 'base64'
require 'timeout'

module ChefMetal
  class Transport
    class WinRM < ChefMetal::Transport
      def initialize(endpoint, type, options = {})
        @endpoint = endpoint
        @type = type
        @options = options
      end

      attr_reader :endpoint
      attr_reader :type
      attr_reader :options

      def execute(command, execute_options = {})
        output = with_execute_timeout(execute_options) do
          session.run_powershell_script(command) do |stdout, stderr|
            stream_chunk(execute_options, stdout, stderr)
          end
        end
        WinRMResult.new(command, execute_options, output)
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
        chunk_size = options[:chunk_size] || 1024
        # TODO if we could marshal this data directly, we wouldn't have to base64 or do this godawful slow stuff :(
        index = 0
        execute("
$ByteArray = [System.Convert]::FromBase64String(#{escape(Base64.encode64(content[index..index+chunk_size-1]))})
$file = [System.IO.File]::Open(#{escape(path)}, 'Create', 'Write')
$file.Write($ByteArray, 0, $ByteArray.Length)
$file.Close
").error!
        index += chunk_size
        while index < content.length
          execute("
$ByteArray = [System.Convert]::FromBase64String(#{escape(Base64.encode64(content[index..index+chunk_size-1]))})
$file = [System.IO.File]::Open(#{escape(path)}, 'Append', 'Write')
$file.Write($ByteArray, 0, $ByteArray.Length)
$file.Close
").error!
          index += chunk_size
        end
      end

      def disconnect
        #
      end

      def escape(string)
        "'#{string.gsub("'", "''")}'"
      end

      protected

      def session
        @session ||= begin
          require 'kconv' # Really, people? *sigh*
          require 'winrm'
          ::WinRM::WinRMWebService.new(endpoint, type, options)
        end
      end

      class WinRMResult
        def initialize(command, options, output)
          @command = command
          @options = options
          @exitstatus = output[:exitcode]
          @stdout = ''
          @stderr = ''
          output[:data].each do |data|
            @stdout << data[:stdout] if data[:stdout]
            @stderr << data[:stderr] if data[:stderr]
          end
        end

        attr_reader :stdout
        attr_reader :stderr
        attr_reader :exitstatus
        attr_reader :command
        attr_reader :options

        def error!
          if exitstatus != 0
            msg = "Error: command '#{command}' exited with code #{exitstatus}.\n"
            msg << "STDOUT: #{stdout}" if !options[:stream] && !options[:stream_stdout] && Chef::Config.log_level != :debug
            msg << "STDERR: #{stderr}" if !options[:stream] && !options[:stream_stderr] && Chef::Config.log_level != :debug
            raise msg
          end
        end
      end
    end
  end
end
