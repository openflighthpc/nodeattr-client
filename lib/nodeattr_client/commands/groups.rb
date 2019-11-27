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

      def list
        group_str = Records::Group.includes(:cluster).all.map do |n|
          "#{n.id}: #{n.cluster&.name}.#{n.name}"
        end
        puts group_str
      end

      def list_nodes(id_or_name, cluster: nil)
        if cluster
          Commands::Nodes.new.list(cluster: cluster, group: id_or_name)
        else
          Commands::Nodes.new.list(group: id_or_name)
        end
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

      private

      def find(id_or_name, cluster)
        id = cluster ? "#{cluster}.#{id_or_name}" : id_or_name
        Records::Group.find(id).first
      end

      def node_rios(ids_or_names_str, cluster)
        ids_or_names = ids_or_names_str.split(',')
        ids = if cluster
                ids_or_names.map { |n| "#{cluster}.#{n}" }
              else
                ids_or_names
              end
        ids.map { |id| { type: Node.type, id: id } }
      end

      def find_update_flag(opts)
        flags = UPDATE_FLAGS.map { |f| opts[f] ? f : nil }.reject(&:nil?)
        if flags.length > 1
          raise InvalidInputs, <<~ERROR.squish
            The following flags can not be used together: #{flags.join(' ')}
          ERROR
        else
          flags.first
        end
      end
    end
  end
end

