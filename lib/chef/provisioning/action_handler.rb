# -*- encoding: utf-8 -*-
#
# Author:: Douglas Triggs (<doug@chef.io>)
#
# Copyright (C) 2014, Chef, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is the generic action handler
class Chef
module Provisioning
  class ActionHandler

    # This should be replaced with whatever records the update; by default it
    # essentially does nothing here.
    def updated!
      @updated = true
    end

    def should_perform_actions
      true
    end

    def report_progress(description)
      Array(description).each { |d| puts d }
    end

    def performed_action(description)
      Array(description).each { |d| puts d }
    end

    # This should perform the actual action (e.g., converge) if there is an
    # action that needs to be done.
    def perform_action(description)
      if should_perform_actions
        result = yield
      else
        result = nil
      end
      performed_action(description)
      result
    end

    # Open a stream which can be printed to and closed
    def open_stream(name)
      if block_given?
        yield STDOUT
      else
        STDOUT
      end
    end

    # A URL identifying the host node. nil if no such node.
    def host_node
    end
  end
end
end
