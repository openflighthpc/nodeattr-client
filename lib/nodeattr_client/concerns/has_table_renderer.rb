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

require 'tty-table'

module NodeattrClient
  module Concerns
    module HasTableRenderer
      def render_table(table_spec, entity_or_entities)
        if entity_or_entities.is_a? Array
          render_standard_table(table_spec, entity_or_entities)
        else
          render_show_table(table_spec, entity_or_entities)
        end
      end

      private

      def render_standard_table(table_spec, entities)
        headers = table_spec.map { |t| t[0] }
        rows = entities.map { |e| table_spec.map { |t| t[1].call(e) } }
        table = TTY::Table.new headers, rows
        table.render
      end

      def render_show_table(table_spec, entity)
        data = table_spec.map { |t| [t[0], t[1].call(entity)] }
        table = TTY::Table.new data
        table.render multiline: true
      end
    end
  end
end

