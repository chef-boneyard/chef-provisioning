module IronChef
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

    def disconnect
      raise "disconnect not overridden on #{self.class}"
    end
  end
end
