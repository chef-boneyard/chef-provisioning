module ChefMetal
  # The base class for machine options - to be extended by drivers to provide
  # a structured class for setting options (well as structured as Ruby gets, for now anyway...)
  class MachineOptions
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