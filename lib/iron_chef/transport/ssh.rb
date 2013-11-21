require 'net/ssh'
require 'net/scp'
require 'iron_chef/transport'

module IronChef
  class Transport
    class SSH < Transport
      def initialize(host, username, ssh_options, options = {})
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
        stdout = ''
        stderr = ''
        exitstatus = nil
        channel = session.open_channel do |channel|
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

        SSHResult.new(stdout, stderr, exitstatus)
      end

      def read_file(path)
        begin
          Net::SCP.new(session).download!(path)
        rescue Net::SCP::Error
          if $!.message =~ /SCP did not finish successfully \(1\)/
            nil
          else
            raise
          end
        end
      end

      def write_file(path, content)
        file = Tempfile.new('putfile')
        begin
          file.write(content)
          file.close

          # Make a tempfile on the other side, upload to that, and sudo mv / chown / etc.
          remote_tempfile = "/tmp/#{File.basename(path)}.#{Random.rand(2**32)}"
          Net::SCP.new(session).upload!(file.path, remote_tempfile)
        ensure
          file.unlink
        end
      end

      def disconnect
        if @session
          @session.close
          @session = nil
        end
      end

      protected

      def session
        @session ||= Net::SSH.start(host, username, ssh_options)
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
          raise "Error: code #{exitstatus}" if exitstatus != 0
        end
      end
    end
  end
end