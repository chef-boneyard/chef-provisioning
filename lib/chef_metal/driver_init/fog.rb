require 'chef_metal_fog/fog_driver'

ChefMetal.register_driver_class("fog", ChefMetalFog::FogDriver)
