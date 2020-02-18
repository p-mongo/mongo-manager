# Mongo Manager

Mongo Manager is a tool for managing MongoDB deployments intended for
development and testing environments, inspired by
[mlaunch](http://blog.rueckstiess.com/mtools/mlaunch.html).
Mongo Manager can provision standalone, replica set and sharded cluster
deployments.

## References

Mongo Manager was developed following the guidance in MongoDB documentation,
specifically the following pages:

- [Auth in a standalone](https://docs.mongodb.com/manual/tutorial/enable-authentication/)
or [here](https://docs.mongodb.com/guides/server/auth/)
- [Create a user in Ruby driver](https://docs.mongodb.com/ruby-driver/current/tutorials/user-management/#creating-users)
- [Deploy a replica set](https://docs.mongodb.com/manual/tutorial/deploy-replica-set/)
and [replSetInitiate reference](https://docs.mongodb.com/manual/reference/command/replSetInitiate/#dbcmd.replSetInitiate)
- [Auth in a replica set](https://docs.mongodb.com/manual/tutorial/deploy-replica-set-with-keyfile-access-control/)
- [Deploy a sharded cluster](https://docs.mongodb.com/manual/tutorial/deploy-shard-cluster/)
and [mongos arguments](https://docs.mongodb.com/manual/reference/program/mongos/#bin.mongos),
[addShard reference](https://docs.mongodb.com/manual/reference/command/addShard/#dbcmd.addShard)
- [Auth in a sharded cluster](https://docs.mongodb.com/manual/tutorial/deploy-sharded-cluster-with-keyfile-access-control/)
- [Ruby driver logging](https://docs.mongodb.com/ruby-driver/current/tutorials/ruby-driver-create-client/#logging)

## License

MIT
