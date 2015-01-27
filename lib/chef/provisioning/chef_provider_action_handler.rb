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

require 'chef/provisioning/action_handler'

# This is included in provisioning drivers to proxy from generic requests needed
# to specific driver actions
class Chef
module Provisioning
  class ChefProviderActionHandler < ActionHandler
    def initialize(provider)
      @provider = provider
    end

    attr_reader :provider

    def updated!
      provider.new_resource.updated_by_last_action(true)
    end

    def should_perform_actions
      !provider.run_context.config.why_run
    end

    def report_progress(description)
      # TODO this seems wrong but Chef doesn't have another thing
      provider.converge_by description do
        # We already did the action, but we trust whoever told us that they did it.
      end
    end

    def performed_action(description)
      provider.converge_by description do
        # We already did the action, but we trust whoever told us that they did it.
      end
    end

    def perform_action(description, &block)
      provider.converge_by(description, &block)
    end

    def open_stream(name, &block)
      if provider.run_context.respond_to?(:open_stream)
        provider.run_context.open_stream({ :name => name }, &block)
      else
        if block_given?
          yield STDOUT
        else
          STDOUT
        end
      end
    end

    def host_node
      "#{provider.run_context.config[:chef_server_url]}/nodes/#{provider.run_context.node['name']}"
    end
  end
end
end
