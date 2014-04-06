module ChefMetal
  class Transport
    def execute(command)
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
  end
end
