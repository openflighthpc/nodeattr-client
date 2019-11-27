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
require 'nodeattr_client/errors'
require 'nodeattr_client/records'

require 'nodeattr_client/concerns/has_param_parser'

require 'nodeattr_client/commands/nodes'
require 'nodeattr_client/commands/groups'
require 'nodeattr_client/commands/clusters'

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

    command 'cluster' do |c|
      cli_syntax(c)
      c.summary = 'View, modify or delete a cluster record'
      c.sub_command_group = true
    end

    command 'group' do |c|
      cli_syntax(c)
      c.summary = 'View, modify, or delete a group/ nodes membership'
      c.sub_command_group = true
    end

    command 'node' do |c|
      cli_syntax(c)
      c.summary = 'View, modify or delete a node'
      c.sub_command_group = true
    end

    {
      'node' => Commands::Nodes,
      'group' => Commands::Groups,
      'cluster' => Commands::Clusters
    }.each do |type, klass|
      plural = type.pluralize
      cluster_opt = ->(c, required: false, ids: nil) do
        c.option '--cluster CLUSTER', <<~DESC.squish
          #{'[REQUIED]' if required}
          Toggle the #{ids || 'ID'} to be #{ids ? 'names' : 'the name'}
          within the CLUSTER
        DESC
      end

      command "#{type} list" do |c|
        cli_syntax(c)
        c.summary = "Return all the #{plural}"
        action(c, klass, method: :list)
      end

      command "#{type} show" do |c|
        cli_syntax(c, 'ID')
        c.summary = "Retrieve a #{type} record and attributes"
        cluster_opt.call(c) unless type == 'cluster'
        action(c, klass, method: :show)
      end

      command "#{type} create" do |c|
        cli_syntax(c, 'NAME [KEY=VALUE...]')
        if type == 'cluster'
          c.summary = 'Create a new cluster record'
        else
          c.summary = "Create a new #{type} within a cluster"
          cluster_opt.call(c)
        end
        action(c, klass, method: :create)
      end

      command "#{type} update" do |c|
        cli_syntax(c, 'ID KEY=VALUE...')
        c.summary = "Modify the parameters for a #{type}"
        cluster_opt.call(c) unless type == 'cluster'
        action(c, klass, method: :update)
      end

      command "#{type} delete" do |c|
        cli_syntax(c, 'ID')
        c.summary = "Permanently delete the #{type}"
        cluster_opt.call(c) unless type == 'cluster'
        action(c, klass, method: :delete)
      end
    end

    #  case type
    #  when 'node'
    #  when 'group'
    #    command "#{plural} update" do |c|
    #      cli_syntax(c, 'GROUP_ID [key=value...]')
    #      c.summary = "Modify group parameters and node membership"
    #      cluster_opt.call(c, ids: "GROUP_ID, NODE_ID1, NODE_ID2, and etc")
    #      c.option '--add-nodes NODE_ID1,NODE_ID2,..."',
    #               'A comma seperated list of node IDs that will be assign to the group'
    #      action(c, klass, method: :update)
    #    end
    #  end
    #end
  end
end

