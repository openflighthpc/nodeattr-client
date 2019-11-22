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

require 'commander'
require 'nodeattr_client/records'

require 'nodeattr_client/commands/node'

module NodeattrClient
  VERSION = '0.0.1'

  class CLI
    extend Commander::Delegates

    program :name, 'flightattr'
    program :version, NodeattrClient::VERSION
    program :description, 'Query for node attributes and grouping'
    program :help_paging, false

    silent_trace!

    def self.run!
      ARGV.push '--help' if ARGV.empty?
      super
    end

    def self.action(command, klass, method: :run!)
      command.action do |args, options|
        hash = options.__hash__
        hash.delete(:trace)
        begin
          begin
            cmd = klass.new
            if hash.empty?
              cmd.public_send(method, *args)
            else
              cmd.public_send(method, *args, **hash)
            end
          rescue Interrupt
            raise RuntimeError, 'Received Interrupt!'
          end
        rescue StandardError => e
          new_error_class = case e
                            when JsonApiClient::Errors::ClientError
                              ClientError
                            when JsonApiClient::Errors::ServerError
                              InternalServerError
                            else
                              nil
                            end
          if new_error_class && e.env.response_headers['content-type'] == 'application/vnd.api+json'
            raise new_error_class, <<~MESSAGE.chomp
              #{e.message}
              #{e.env.body['errors'].map do |e| e['detail'] end.join("\n\n")}
            MESSAGE
          else
            raise e
          end
        end
      end
    end

    def self.cli_syntax(command, args_str = '')
      command.hidden = true if command.name.split.length > 1
      command.syntax = <<~SYNTAX.chomp
        #{program(:name)} #{command.name} #{args_str}
      SYNTAX
    end

    command 'nodes' do |c|
      cli_syntax(c)
      c.sub_command_group = true
      c.summary = 'Preform an action on multiple nodes'
    end

    command 'nodes list' do |c|
      cli_syntax(c)
      c.summary = 'List all the nodes'
      action(c, Commands::Node, method: :list)
    end

    command 'node' do |c|
      cli_syntax(c)
      c.sub_command_group = true
      c.summary = 'Preform an action on a single node'
    end

    command 'node show' do |c|
      cli_syntax(c, 'ID')
      c.summary = 'Retreive the record about a single node'
      c.option '--cluster CLUSTER',
               'Toggle the ID to be node name within the given cluster'
      action(c, Commands::Node, method: :show)
    end

    command 'node update' do |c|
      cli_syntax(c, 'ID KEY=VALUE...')
      c.summary = 'Update the parameters for a node'
      c.option '--cluster CLUSTER',
               'Toggle the ID to be node name within the given cluster'
      action(c, Commands::Node, method: :update)
    end
  end
end

