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
    class Groups
      include Concerns::HasParamParser

      UPDATE_FLAGS = [:add_nodes]

      def list_nodes(id_or_name, cluster: nil)
        Commands::Nodes.new.list(cluster: cluster, group: id_or_name)
      end

      def list(cluster: nil, cluster_id: nil, node: nil)
        records = if node
                    id = (cluster ? "#{cluster}.#{node}" : node)
                    Records::Group.where(node_id: id).includes(:cluster).all
                  elsif cluster || cluster_id
                    id = (cluster ? ".#{cluster}" : cluster_id)
                    Records::Group.where(cluster_id: id).includes(:cluster).all
                  else
                    Records::Group.includes(:cluster).all
                  end
        group_str = records.map do |group|
          "#{group.id}: #{group.cluster&.name}.#{group.name}"
        end
        puts group_str
      end

      def show(id, cluster: nil)
        pp find(id, cluster)
      end

      def create(name, *params, cluster: nil)
        raise InvalidInput, <<~ERROR.squish unless cluster
          The '--cluster CLUSTER' flag must be specified on create
        ERROR
        group = Records::Group.create(
          name: name,
          level_params: parse_params(*params),
          relationships: { cluster: Records::Cluster.new(id: ".#{cluster}") }
        )
        pp group
      end

      def update(id, *params, cluster: nil)
        group = find(id, cluster)
        group.update params: group.params.merge(parse_params(*params))
        pp group
      end

      def delete(id, cluster: nil)
        group = find(id, cluster)
        pp group.destroy
      end

      def add_nodes(*a)
        group_nodes_command(*a) do |group, nodes|
          group.nodes_relationship.merge(*nodes)
        end
      end

      def replace_nodes(*a)
        group_nodes_command(*a) do |group, nodes|
          group.nodes_relationship.replace(*nodes)
        end
      end

      def clear_nodes(id_or_name, cluster: false)
        id = resolve_ids(id_or_name, cluster)
        Records::Group.new(id: id).nodes_relationship.clear
      end

      def remove_nodes(*a)
        group_nodes_command(*a) do |group, nodes|
          group.nodes_relationship.subtract(*nodes)
        end
      end

      private

      def group_nodes_command(id_or_name, *node_ids_or_names, cluster: false)
        id = resolve_ids(id_or_name, cluster)
        node_ids = resolve_ids(node_ids_or_names, cluster)
        group = Records::Group.new(id: id)
        nodes = node_ids.map { |i| Records::Node.new(id: i) }
        yield(group, nodes)
        pp group
      end

      def resolve_ids(ids_or_names, cluster)
        if cluster
          ids = Array.wrap(ids_or_names).map { |n| "#{cluster}.#{n}" }
          ids_or_names.is_a?(Array) ? ids : ids.first
        else
          ids_or_names
        end
      end

      def find(id_or_name, cluster)
        id = resolve_ids(id_or_name, cluster)
        Records::Group.find(id).first
      end
    end
  end
end

