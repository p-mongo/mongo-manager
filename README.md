# Mongo Manager

Mongo Manager is a tool for managing MongoDB deployments intended for
development and testing environments, inspired by
[mlaunch](http://blog.rueckstiess.com/mtools/mlaunch.html).
Mongo Manager can provision standalone, replica set and sharded cluster
deployments.

## Provisioning

The most common operation that Mongo Manager performs is provisioning a new
MongoDB deployment. This is accomplished by invoking `mongo-manager` with
the `init` argument and the deployment base directory, as follows:

    mongo-manager --dir /path/to/deployment init [options]

The above command will create a new MongoDB deployment at `/path/to/deployment`.
By default, the deployment will be a standalone server with no authentication
listening on the default port, 27017.

Use the options to customize the deployment, as described below.

### General

- `--bin-dir PATH`: specify the directory where `mongod` and `mongos`
binaries are located. Mongo Manager does not use the `mongo` binary.

### Ports

- `--port PORT`: use the specified port number as the base port on which
daemons will be listening.

If the deployment is a standalone server, it will listen on the specified
port. If the deployment is a replica set, the nodes will use consecutive
ports starting with the specfied base port. If the deployment is a sharded
cluster, ports are allocated sequentally in the following order:

- `mongos` instance(s)
- Config server(s)
- Shard(s)

For example, a sharded cluster with 2 `mongos` routers and 3-node replica
sets for the config server and each of the two shards would use the
following ports by default:

- 27017: `mongos` 1
- 27018: `mongos` 2
- 27019: config server node 1
- 27020: config server node 2
- 27021: config server node 3
- 27022: shard 1 node 1
- 27023: shard 1 node 2
- 27023: shard 1 node 3
- 27024: shard 2 node 1
- 27025: shard 2 node 2
- 27026: shard 2 node 3

Note that by default, `mongocryptd` listens on port 27020. This makes it
incompatible with most sharded cluster deployments that start on port 27017.
The only sharded cluster deployment that utilizes three ports is one with
a 1-node config server replica set, a single shard consisting of 1-node
replica set, and a single `mongos`. To use automatic encryption with a
sharded cluster deployment, either `mongocryptd` or the deployment must
generally be started on a non-default port.

### Topology

- `--replica-set NAME`: create a replica set with the specified name.
- `--sharded NUM`: create a sharded cluster with NUM shards. By default,
each shard is a standalone server.
- `--mongos NUM`: create a sharded cluster with NUM mongos.

## License

MIT
