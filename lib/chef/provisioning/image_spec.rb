class Chef
module Provisioning
  #
  # Specification for a image. Sufficient information to find and contact it
  # after it has been set up.
  #
  class ImageSpec
    def initialize(image_data)
      @image_data = image_data
    end

    attr_reader :image_data

    #
    # Globally unique identifier for this image. Does not depend on the image's
    # location or existence.
    #
    def id
      raise "id unimplemented"
    end

    #
    # Name of the image. Corresponds to the name in "image 'name' do" ...
    #
    def name
      image_data['id']
    end

    #
    # Location of this image. This should be a freeform hash, with enough
    # information for the driver to look it up and create a image object to
    # access it.
    #
    # This MUST include a 'driver_url' attribute with the driver's URL in it.
    #
    # chef-provisioning will do its darnedest to not lose this information.
    #
    def location
      image_data['location']
    end

    #
    # Set the location for this image.
    #
    def location=(value)
      image_data['location'] = value
    end

    def machine_options
      image_data['machine_options']
    end

    def machine_options=(value)
      image_data['machine_options'] = value
    end

    # URL to the driver.  Convenience for location['driver_url']
    def driver_url
      location ? location['driver_url'] : nil
    end

    #
    # Save this image_data to the server.  If you have significant information that
    # could be lost, you should do this as quickly as possible.  image_data will be
    # saved automatically for you after allocate_image and ready_image.
    #
    def save(action_handler)
      raise "save unimplemented"
    end
  end
end
end
