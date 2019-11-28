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

module NodeattrClient
  module Commands
    class Clusters
      include Concerns::HasParamParser
      include Concerns::HasTableRenderer

      LIST_TABLE = [
        ['ID', ->(c) { c.id }],
        ['Name', ->(c) { c.name }]
      ]

      def list_nodes(id_or_name, name: false)
        if name
          Nodes.new.list(cluster: id_or_name)
        else
          Nodes.new.list(cluster_id: id_or_name)
        end
      end

      def list_groups(id_or_name, name: false)
        if name
          Groups.new.list(cluster: id_or_name)
        else
          Groups.new.list(cluster_id: id_or_name)
        end
      end

      def list
        clusters = Records::Cluster.all
        puts render_table(LIST_TABLE, clusters)
      end

      def show(id_or_name, name: false)
        pp find(id_or_name, name)
      end

      def create(name_input, *params, name: nil)
        $stderr.puts <<~WARN.squish unless name
          --name has not been specified. The input is being interpreted as the cluster name not
          an ID. All other cluster commands use the cluster ID by default.
        WARN
        cluster = Records::Cluster.create(name: name_input, level_params: parse_params(*params))
        pp cluster
      end

      def update(id_or_name, *params, name: false)
        cluster = find(id_or_name, name)
        cluster.update level_params: cluster.params.merge(parse_params(*params))
        pp cluster
      end

      def delete(id_or_name, name: false)
        cluster = find(id_or_name, name)
        pp cluster.destroy
      end

      private

      def find(id_or_name, name)
        id = name ? ".#{id_or_name}" : id_or_name
        Records::Cluster.find(id).first
      end
    end
  end
end

