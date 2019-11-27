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

      def list_groups(id_or_name, cluster: nil)
        Commands::Groups.new.list(cluster: cluster, node: id_or_name)
      end

      def list(cluster: nil, cluster_id: nil, group: nil)
        records = if group
                    id = (cluster ? "#{cluster}.#{group}" : group)
                    Records::Node.where(group_id: id).includes(:cluster).all
                  elsif cluster || cluster_id
                    id = (cluster ? ".#{cluster}" : cluster_id)
                    Records::Node.where(cluster_id: id).includes(:cluster).all
                  else
                    Records::Node.includes(:cluster).all
                  end
        nodes_str = records.map do |node|
          "#{node.id}: #{node.cluster&.name}.#{node.name}"
        end
        puts nodes_str
      end

      def show(id, cluster: nil)
        pp find(id, cluster)
      end

      def create(name, *params, cluster: nil)
        raise InvalidInput, <<~ERROR.squish unless cluster
          The '--cluster CLUSTER' flag must be specified on create
        ERROR
        node = Records::Node.create(
          name: name,
          level_params: parse_params(*params),
          relationships: { cluster: Records::Cluster.new(id: ".#{cluster}") }
        )
        pp node
      end

      def update(id, *params, cluster: nil)
        node = find(id, cluster)
        node.update params: node.params.merge(parse_params(*params))
        pp node
      end

      def delete(id, cluster: nil)
        node = find(id, cluster)
        pp node.destroy
      end

      private

      def find(id_or_name, cluster)
        id = cluster ? "#{cluster}.#{id_or_name}" : id_or_name
        Records::Node.find(id).first
      end
    end
  end
end

