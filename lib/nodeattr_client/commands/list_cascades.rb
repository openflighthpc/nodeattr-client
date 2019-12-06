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
    class ListCascades
      include Concerns::HasTableRenderer
      include Concerns::HasResolveIdFromCluster

      LIST_TABLE = [
        ['ID',      ->(r) { r.id }],
        ['Cluster', ->(r) { r.is_a?(Cluster) ? r.name : r.cluster.name }],
        ['Name',    ->(r) { r.name }],
        ['Type',    ->(r) { r.class.type.singularize }]
      ]

      def node(id_or_name, cluster: nil)
        id = resolve_ids(id_or_name, cluster)
        models = Cascades.includes(:cluster).where(node_id: id).all
        list_cascades(models)
      end

      def group(id_or_name, cluster: nil)
        id = resolve_ids(id_or_name, cluster)
        models = Cascades.includes(:cluster).where(group_id: id).all
        list_cascades(models)
      end

      def cluster(id_or_name, name: false)
        id = resolve_cluster_id(id_or_name, name)
        models = Cascades.where(cluster_id: id).all
        list_cascades(models)
      end

      private

      def list_cascades(models)
        puts render_table(LIST_TABLE, models)
      end

      def resolve_cluster_id(id_or_name, name)
        name ? ".#{id_or_name}" : id_or_name
      end
    end
  end
end
