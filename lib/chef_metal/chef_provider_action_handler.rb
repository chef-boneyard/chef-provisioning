# -*- encoding: utf-8 -*-
#
# Author:: Douglas Triggs (<doug@getchef.com>)
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

# This is included in the metal drivers to proxy from generic requests needed
# to specific driver actions
module ChefMetal
  module ChefProviderActionHandler
    # Implementation of ActionHandler interface

    def updated!
      self.new_resource.updated_by_last_action(true)
    end

    def should_perform_actions
      !Chef::Config.why_run
    end

    def report_progress(description)
      # TODO this seems wrong but Chef doesn't have another thing
      self.converge_by description do
        # We already did the action, but we trust whoever told us that they did it.
      end
    end

    def performed_action(description)
      self.converge_by description do
        # We already did the action, but we trust whoever told us that they did it.
      end
    end

    def perform_action(description, &block)
      self.converge_by(description, &block)
    end

    def debug_name
      self.cookbook_name
    end

    def open_stream(name, &block)
      if self.run_context.respond_to?(:open_stream)
        self.run_context.open_stream({ :name => name }, &block)
      else
        if block_given?
          yield STDOUT
        else
          STDOUT
        end
      end
    end
  end
end
