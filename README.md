# Nodeattr Client

Query tool for node attributes and grouping information

## Overview

## Installation

### Preconditions

The following are required to run this application:

* OS:     Centos7
* Ruby:   2.6+
* Bundler

### Manual installation

Start by cloning the repo, adding the binaries to your path, and install the gems:

```
git clone https://github.com/openflighthpc/nodeattr-client
cd nodeattr-client
bundle install --without development test --path vendor
```

### Configuration

These application needs a couple of configuration parameters to specify which server to communicate with. Refer to the [reference config](etc/config.yaml.reference) for the required keys. The configs needs to be stored within `etc/config.yaml`.

```
cd /path/to/client
touch etc/config.yaml
vi etc/config.yaml
```

## Basic Usage
The following are the steps for creating a basic cluster containing nodes and gpus:

### Cluster Configuration

The following commands will create and display the cluster `foo`:

```
# Create the new cluster
$ bin/flightattr cluster create --name foo

# Find the cluster ID
$ bin/flightattr list-clusters
ID        Name
<foo-id>  foo

# Display the cluster details by name
$ bin/flightattr cluster show --name foo

# Equivalent to
$ bin/flightattr cluster show <foo-id>
```

The default parameters for the cluster are set directly on the cluster. This can be done on `create` above or later using the `update` command:

```
# Sets the demo default settings for the parameter engine
$ bin/flightattr cluster update --name foo key_cluster=cluster key_nodes=cluster key_gpus=cluster key_node01=cluster key_gpu01=cluster

# Equivalent to:
$ bin/flightattr cluster update <foo-id> key_cluster=...(as above)...
```

### Group Configuration

Groups are used to identify collections of nodes and provide greater granularity to the parameter engine. This can be done via the two step `create`/`update` process or within a single `create`:

```
# Create a group using the two step method:
$ bin/flightattr group create --cluster foo nodes
$ bin/flightattr group update --cluster foo nodes key_nodes=nodes key_node01=nodes

# Equivalent to:
$ bin/flightattr group update <nodes-id> key_nodes=...(as above)...

# Create a group in a single step
# NOTE: A cluster can be created in the same manner
$ bin/flightattr group create --cluster foo gpus key_gpus=gpus key_gpu01=gpus
```

The following will list the groups and show the results from the parameter engine:

```
# List the groups
$ bin/flightattr list-groups

# Limit the list to the foo cluster
$ bin/flightattr cluster list-groups --name foo

# Equivalent to:
$ bin/flightattr cluster list-groups <foo-id>

# View the nodes group by name
$ bin/flightattr group show --cluster foo nodes

# Equivalent to:
$ bin/flightattr group show <nodes-id>
```

### Node Configuration

Finally the nodes can be created and placed into the groups. This can be done via a two step `create`/`add-nodes` or three step `create`/`update`/`add-nodes` process.

```
# Create the nodes with parameters in a single step
$ bin/flightattr node create --cluster foo node01 key_node01=node01
$ bin/flightattr node create --cluster foo node02
$ bin/flightattr node create --cluster foo gpu02

# Create a node and update it with parameters
$ bin/flightattr node create --cluster foo gpu01
$ bin/flightattr node update --cluster foo gpu01 key_gpu01=gpu01

# Equivalent to:
$ bin/flightattr node update <gpu01-id> key_gpu01=...(as above)...

# Add the nodes to there respective groups
$ bin/flightattr group add-nodes --cluster foo nodes node01 node02
$ bin/flightattr group add-nodes --cluster foo gpus gpu01 gpu02

# Equivalent to:
$ bin/flightattr group add-nodes <nodes-id> <node01-id> <node02-id>
$ bin/flightattr group add-ndoes <gpus-id> <gpu01-id> <gpu02-id>
```

The following can be used to view the nodes and parameters:

```
# List all the nodes
$ bin/flightattr list-nodes

# List all the nodes within the foo cluster (and equivalents):
$ bin/flightattr cluster list-nodes --name foo
$ bin/flightattr cluster list-nodes <foo-id>

# List all the nodes within a group (and equivalent):
# NOTE: Each group is cluster specific, it not possible to list nodes with the same group name across clusters
$ bin/flightattr group list-nodes --cluster foo nodes
$ bin/flightattr group list-nodes <nodes-id>

# List all the groups that a node is part of (and equivalent)
$ bin/flightattr node list-groups --cluster foo node01
$ bin/flightattr node list-groups <node01-id>

# Show the details about a node (and equivalent)
$ bin/flightattr node show --cluster foo gpu01
$ bin/flightattr node show <gpu01-id>
```

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Creative Commons Attribution-ShareAlike 4.0 License, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

You should have received a copy of the license along with this work.
If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.

![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

nodeattr Client is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Based on a work at [https://github.com/openflighthpc/openflight-tools](https://github.com/openflighthpc/openflight-tools).

This content and the accompanying materials are made available available
under the terms of the Creative Commons Attribution-ShareAlike 4.0
International License which is available at [https://creativecommons.org/licenses/by-sa/4.0/](https://creativecommons.org/licenses/by-sa/4.0/),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

nodeattr Client is distributed in the hope that it will be useful, but
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF
TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR
PURPOSE. See the [Creative Commons Attribution-ShareAlike 4.0
International License](https://creativecommons.org/licenses/by-sa/4.0/) for more
details.
