require 'winrm'

module IronChef
  module Transport
    class WinRM
      def initialize(endpoint, type, options = {})
        @endpoint = endpoint
        @type = type
        @options = options
      end

      def execute
      end

      def disconnect
        if @winrm
        end
      end

      def service
        @service ||= WinRM::WinRMWebService.new(endpoint, type, options)
      end
    end
  end
end