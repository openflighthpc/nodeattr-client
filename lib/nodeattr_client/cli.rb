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

    {
      'node' => Commands::Nodes,
      'group' => Commands::Groups
    }.each do |type, klass|
      plural = type.pluralize
      cluster_opt = ->(c, required = false) do
        c.option '--cluster CLUSTER', <<~DESC.squish
          #{'[REQUIED]' if required}
          Toggle the ID to be name of the #{type} within the CLUSTER
        DESC
      end


      command plural do |c|
        cli_syntax(c)
        c.sub_command_group = true
        c.summary = "Manage the #{type} records"
      end

      command "#{plural} list" do |c|
        cli_syntax(c)
        c.summary = "List all the #{plural}"
        action(c, klass, method: :list)
      end

      command "#{plural} show" do |c|
        cli_syntax(c, 'ID')
        c.summary = "Retreive the record for a single #{type}"
        cluster_opt.call(c)
        action(c, klass, method: :show)
      end

      command "#{plural} create" do |c|
        cli_syntax(c, 'NAME [KEY=VALUE...]')
        c.summary = "Create a new #{type} within a cluster"
        cluster_opt.call(c, true)
        action(c, klass, method: :create)
      end

      command "#{plural} update" do |c|
        cli_syntax(c, 'ID KEY=VALUE...')
        c.summary = "Modify the parameters for a #{type}"
        cluster_opt.call(c)
        action(c, klass, method: :update)
      end

      command "#{plural} delete" do |c|
        cli_syntax(c, 'ID')
        c.summary = "Permanently delete the #{type}"
        cluster_opt.call(c)
        action(c, klass, method: :delete)
      end
    end

    command 'clusters' do |c|
      cli_syntax(c)
      c.summary = 'Manage the cluster resources'
      c.sub_command_group = true
    end

    command 'clusters list' do |c|
      cli_syntax(c)
      c.summary = 'List all the clusters'
      action(c, Commands::Clusters, method: :list)
    end

    command 'clusters show' do |c|
      cli_syntax(c, 'ID')
      c.summary = 'Retrieve a single cluster record'
      c.option '-n', '--name', 'Find the record by name instead of ID'
      action(c, Commands::Clusters, method: :show)
    end

    command 'clusters create' do |c|
      cli_syntax(c, 'NAME [KEY=VALUE...]')
      c.summary = 'Add a new cluster entry'
      action(c, Commands::Clusters, method: :create)
    end

    command 'clusters update' do |c|
      cli_syntax(c, 'ID [KEY=VALUE...]')
      c.summary = "Modify the parameters for an existing cluster"
      c.option '-n', '--name', 'Find the record by name instead of ID'
      action(c, Commands::Clusters, method: :update)
    end

    command 'clusters delete' do |c|
      cli_syntax(c, 'ID')
      c.summary = 'Permanently remove the cluster record'
      c.option '-n', '--name', 'Find the record by name instead of ID'
      action(c, Commands::Clusters, method: :delete)
    end
  end
end

