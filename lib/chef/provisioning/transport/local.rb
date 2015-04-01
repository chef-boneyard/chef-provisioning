require 'chef/provisioning/transport'
require 'chef/mixin/shell_out'
require 'chef/log'

class Chef
module Provisioning
  class Transport
    class Local < Chef::Provisioning::Transport
      include Chef::Mixin::ShellOut

      #
      # Create a new local transport.
      #
      # == Arguments
      #
      # - options: a hash of options for the transport itself, including:
      #   - :prefix: a prefix to send before each command (e.g. "sudo ")
      # - global_config: an options hash that looks suspiciously similar to
      #   Chef::Config, containing at least the key :log_level.
      #
      # The options are used in
      #   Net::SSH.start(host, username, ssh_options)

      def initialize(options, global_config)
        @options = options
        @config = global_config
      end

      attr_reader :options
      attr_reader :config

      def execute(command, execute_options = {})
        Chef::Log.info("Executing #{options[:prefix]}#{command} locally")
        result = shell_out!(command, execute_options)
        Chef::Log.info("Completed #{command} on #{username}@#{host}: exit status #{exitstatus}")
        Chef::Log.debug("Stdout was:\n#{stdout}") if stdout != '' && !options[:stream] && !options[:stream_stdout] && config[:log_level] != :debug
        Chef::Log.info("Stderr was:\n#{stderr}") if stderr != '' && !options[:stream] && !options[:stream_stderr] && config[:log_level] != :debug
        result
      end

      def read_file(path)
        IO.read(path)
      end

      def write_file(path, content)
        IO.write(path, content)
      end

      # TODO do we need to bind_to?  Probably.
      def make_url_available_to_remote(local_url, **options)
        local_url
      end

      def disconnect
      end

      def available?
        true
      end
    end
  end
end
end
