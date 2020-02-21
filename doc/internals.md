# Mongo Manager Internals

## References

MM was developed following the guidance in MongoDB documentation,
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
- [Configure TLS](https://docs.mongodb.com/manual/tutorial/configure-ssl/)

## Differences From mlaunch

- MM does not try to parse (and thus, does not need to have knowledge of)
all server arguments. Instead, MM provides mechanisms for argument passthrough
for all processes as well as `mongod`/`mongos` only.
- MM creates one state/data directory per launched process (`mongod`/`mongos`).
`mongos` do not hold data but they still produce a log and a pid file.
- MM configures all `mongod` and `mongos` processes to write a pid file,
which is used to kill them later.
- MM names log and pid files after the basename of the binary in all cases,
e.g. `mongos.log` and `mongos.pid`. mlaunch uses `mongos_#{port}.log` for
`mongos` log files since it places multiple files in the same directory.

## Diagnostics

MM generally provides the following diagnostics:

- Whenever a process start or stop fails, MM excerpts the last few lines
of the respective process's log file.

## Stopping

In a sharded cluster, if the config server `mongod`s are killed before
shard nodes `mongod`, the shard nodes may [take up to about
a minute](https://gist.github.com/p-mongo/bd500e1ff88cc555ef6b920d7a47c658)
to stop.

MM deals with this by killing the daemons in the reverse order of starting,
and waiting for each daemon before proceeding to the next one. This means
the order of daemon directories in the settings file is significant.
It is possible to kill groups of processes (i.e. kill all `mongos`, wait,
kill all shard `mongod`s, wait, kill all config server `mongod`s) but
this would introduce too much complexity at the current juncture.

Standalone and replica set topologies use a more optimized stopping procedure
where all daemons are killed and then all are waited for, since the order
of daemon destruction does not matter.

## Daemonization In Containers

In order for the tests to pass when they are run in a container environment
like Docker, the environment must have an init process. This must be
requested via the `--init` option to `docker run`, for example. Otherwise
dead `mongod`/`mongos` will not be getting reaped.

Resources regarding daemonization:

- [Proper way to daemonize](https://stackoverflow.com/questions/473620/how-do-you-create-a-daemon-in-python),
[the pep](https://www.python.org/dev/peps/pep-3143/),
[python-daemon source](https://pagure.io/python-daemon/blob/master/f/daemon/daemon.py)
- [Detaching when forking](https://stackoverflow.com/questions/881388/what-is-the-reason-for-performing-a-double-fork-when-creating-a-daemon)
- [More on process groups](https://unix.stackexchange.com/questions/363126/why-is-process-not-part-of-expected-process-group)
- [tini](https://github.com/krallin/tini) - init for containers
- [How to handle pid files](https://stackoverflow.com/questions/688343/reference-for-proper-handling-of-pid-file-on-unix)
- [man setsid](https://linux.die.net/man/2/setsid), [man setpgrp](https://linux.die.net/man/2/setpgrp)

## Replica Sets

When initiating a replica set (i.e. calling `replSetInitiate`), the node
on which initiation is invoked, on server 3.0 at least, does not wait for any
sort of a timeout for the other nodes. If any of the other nodes are still
starting and are not yet available, `replSetInitiate` immediately fails.
MM works around this by waiting for each node separately before trying to
initiate the replica set.
