require 'chef_metal_fog/fog_driver'

ChefMetal.add_registered_driver_class("fog", ChefMetalFog::FogDriver)
