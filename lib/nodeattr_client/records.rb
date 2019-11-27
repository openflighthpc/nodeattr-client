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
  module Records
    class Base < JsonApiClient::Resource
      # TODO: Make this a config value
      self.site = "http://localhost:8080"
    end

    class Node < Base
      belongs_to :cluster, class_name: "#{module_parent}::Cluster", shallow_path: true
      has_many :groups, class_name: "#{module_parent}::Group"

      property :name, type: :string
      property :params, type: :hash
    end

    class Group < Base
      belongs_to :cluster, class_name: "#{module_parent}::Cluster", shallow_path: true
      has_many :nodes, class_name: "#{module_parent}::Node"

      property :name, type: :string
    end

    class Cluster < Base
      has_many :nodes, class_name: "#{module_parent}::Node"
      has_many :groups, class_name: "#{module_parent}::Group"

      property :name, type: :string
    end
  end
end

