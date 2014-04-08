module ChefMetal
  class Transport
    def execute(command, options = {})
      raise "execute not overridden on #{self.class}"
    end

    def read_file(path)
      raise "read_file not overridden on #{self.class}"
    end

    def write_file(path, content)
      raise "write_file not overridden on #{self.class}"
    end

    def download_file(path, local_path)
      IO.write(local_path, read_file(path))
    end

    def upload_file(local_path, path)
      write_file(path, IO.read(local_path))
    end

    def make_url_available_to_remote(local_url)
      raise "make_url_available_to_remote not overridden on #{self.class}"
    end

    def disconnect
      raise "disconnect not overridden on #{self.class}"
    end

    def available?
      raise "available? not overridden on #{self.class}"
    end

    protected

    # Helper to implement stdout/stderr streaming in execute
    def stream_chunk(options, stdout_chunk, stderr_chunk)
      if options[:stream].is_a?(Proc)
        options[:stream].call(stdout_chunk, stderr_chunk)
      else
        if stdout_chunk
          if options[:stream_stdout]
            options[:stream_stdout].print stdout_chunk
          elsif options[:stream]
            STDOUT.print stdout_chunk
          end
        end
        if stderr_chunk
          if options[:stream_stderr]
            options[:stream_stderr].print stderr_chunk
          elsif options[:stream]
            STDERR.print stderr_chunk
          end
        end
      end
    end
  end
end
