# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Nodeattr Client.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Nodeattr Client is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Nodeattr Client. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Nodeattr Client, please visit:
# https://github.com/openflighthpc/nodeattr-client
#===============================================================================

require 'json_api_client'

module NodeattrClient
  # Remove the 'Records' module to make refactoring the client into a library easier
  # TODO: Remove references to 'Records' completely
  Records = NodeattrClient

  class Base < JsonApiClient::Resource
    # TODO: Make this a config value
    self.site = "http://localhost:8080"
  end

  # NOTE: JsonApiClient::Resource implements a bunch of relationship functionality
  # using `belongs_to` instead of has_one/has_many, for reasons ¯\_(ツ)_/¯
  #
  # This is only used for syntactic sugar and has no correlation to the data model!

  class Node < Base
    belongs_to :cluster, class_name: "#{module_parent}::Cluster", shallow_path: true
    belongs_to :group, class_name: "#{module_parent}::Group", shallow_path: true

    property :name, type: :string
    property :params, type: :hash
  end

  GroupNodesRelationship = Struct.new(:group) do
    def merge(*nodes)
      connection.run(:post, path, body: build_payload(*nodes))
    end

    def replace(*nodes)
      connection.run(:patch, path, body: build_payload(*nodes))
    end

    def clear
      connection.run(:patch, path, body: { data: [] }.to_json)
    end

    def subtract(*nodes)
      connection.run(:delete, path, body: build_payload(*nodes))
    end

    private

    def build_payload(*nodes)
      { data: nodes.map(&:as_relation) }.to_json
    end

    def path
      "/#{Group.type}/#{group.id}/relationships/#{Node.type}"
    end

    def connection
      group.class.connection
    end
  end

  class Group < Base
    belongs_to :cluster, class_name: "#{module_parent}::Cluster", shallow_path: true
    belongs_to :node, class_name: "#{module_parent}::Node", shallow_path: true

    property :name, type: :string

    def nodes_relationship
      @nodes_relationship ||= GroupNodesRelationship.new(self)
    end
  end

  class Cluster < Base
    belongs_to :group, class_name: "#{module_parent}::Group", shallow_path: true
    belongs_to :node, class_name: "#{module_parent}::Node", shallow_path: true

    property :name, type: :string
  end
end

