require 'chef/provisioning/managed_entry'

class Chef
module Provisioning
  #
  # Specification for a image. Sufficient information to find and contact it
  # after it has been set up.
  #
  class LoadBalancerSpec < ManagedEntry
    alias :location :reference
    alias :location= :reference=
  end
end
end
