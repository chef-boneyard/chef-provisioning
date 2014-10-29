module ChefMetal
  # The base class for bootstrap options that are used by the
  # corresponding driver when bootstrapping a new machine. These
  # include things like what type of machine to construct,
  # image to construct the machine from, etc.
  class BootstrapOptions
    class << self
      # A list of attributes that this thing has
      attr_reader :attributes
    end

    # Override attr_accessor to track the things that can be serialized
    def self.attr_accessor(*vars)
      @attributes ||= []
      @attributes.concat vars
      super
    end

    # Take all the desired attributes and stuff them in a hash
    # @return [Hash] A hash of the attributes for serialization
    def to_hash
      hash = {}
      ignored = self.class.ignored_attributes
      (self.class.attributes - ignored).each do |attr_name|
        varname = "@#{attr_name.to_s.gsub('@', '')}"
        key = varname.gsub('@', '')
        hash[key] = self.instance_variable_get varname
      end

      hash
    end

  end
end