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
        rescue
          if $!.message =~ /SCP did not finish successfully \(1\)/ || $!.message =~ /No such file or directory/
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

          if options[:prefix]
            # Make a tempfile on the other side, upload to that, and sudo mv / chown / etc.
            remote_tempfile = "/tmp/#{File.basename(path)}.#{Random.rand(2**32)}"
            Net::SCP.new(session).upload!(file.path, remote_tempfile)
            execute("mv #{remote_tempfile} #{path}")
          else
            Net::SCP.new(session).upload!(file.path, path)
          end
        ensure
          file.unlink
        end
      end

      def forward_remote_port_to_local(remote_port, local_port)
        # TODO IPv6
        session.forward.remote(local_port, "127.0.0.1", remote_port)
      end

      def disconnect
        if @session
          begin
            @session.close
          rescue
          end
          @session = nil
        end
      end

      protected

      def session
        @session ||= begin
          Net::SSH.start(host, username, ssh_options)
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