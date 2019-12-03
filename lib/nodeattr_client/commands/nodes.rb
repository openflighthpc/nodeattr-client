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
    class Nodes
      include Concerns::HasParamParser
      include Concerns::HasTableRenderer
      include Concerns::HasResolveIdFromCluster

      LIST_TABLE = [
        ['ID',      ->(n) { n.id }],
        ['Cluster', ->(n) { n.cluster.name }],
        ['Name',    ->(n) { n.name }]
      ]

      SHOW_TABLE = [
        ['ID',          ->(n) { n.id }],
        ['Name',        ->(n) { n.name }],
        ['Cluster',     ->(n) { n.cluster.name }],
        ['Groups',      ->(n) { n.groups.map(&:name).join(',') }],
        ['Parameters',  ->(n) { JSON.pretty_generate(n.params) }]
      ]

      def list_groups(id_or_name, cluster: nil)
        Commands::Groups.new.list(cluster: cluster, node: id_or_name)
      end

      def list(cluster: nil, cluster_id: nil, group: nil)
        nodes = if group
                  id = (cluster ? "#{cluster}.#{group}" : group)
                  Records::Node.where(group_id: id).includes(:cluster).all
                elsif cluster || cluster_id
                  id = (cluster ? ".#{cluster}" : cluster_id)
                  Records::Node.where(cluster_id: id).includes(:cluster).all
                else
                  Records::Node.includes(:cluster).all
                end
        puts render_table(LIST_TABLE, nodes)
      end

      def show(name_or_id, cluster: nil)
        id = resolve_ids(name_or_id, cluster)
        node = Records::Node.includes(:cluster, :groups).find(id).first
        puts render_table(SHOW_TABLE, node)
      end

      def create(name, *params, cluster: nil)
        raise InvalidInput, <<~ERROR.squish unless cluster
          The '--cluster CLUSTER' flag must be specified on create
        ERROR
        Records::Node.create(
          name: name,
          level_params: parse_params(*params),
          relationships: { cluster: Records::Cluster.new(id: ".#{cluster}") }
        )
      end

      def update(name_or_id, *params, cluster: nil)
        id = resolve_ids(name_or_id, cluster)
        node = Records::Node.find(id).first
        node.update level_params: node.params.merge(parse_params(*params))
      end

      def delete(name_or_id, cluster: nil)
        id = resolve_ids(name_or_id, cluster)
        Records::Node.new(id: id).destroy
      end
    end
  end
end

