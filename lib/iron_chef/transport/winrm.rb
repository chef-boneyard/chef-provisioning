module IronChef
  class Transport
    class WinRM
      def initialize(endpoint, type, options = {})
        @endpoint = endpoint
        @type = type
        @options = options
      end

      attr_reader :endpoint
      attr_reader :type
      attr_reader :options

      def execute(command)
        output = session.run_powershell_script(command)
        WinRMResult.new(output)
      end

      def read_file(path)
        execute("Get-Content #{escape_string(path)}")
      end

      def write_file(path, content)
        execute("Set-Content #{escape_string(path)} #{escape_string(path)}")
      end

      def disconnect
        # 
      end

      def escape_string(string)
        "'#{string.gsub("'", "''")}'"
      end

      protected

      def session
        @session ||= begin
          require 'winrm'
          ::WinRM::WinRMWebService.new(endpoint, type, options)
        end
      end

      class WinRMResult
        def initialize(output)
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

        def error!
          raise "Error: code #{exitstatus}" if exitstatus != 0
        end
      end
    end
  end
end
