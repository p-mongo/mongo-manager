require 'fileutils'
require 'pathname'

module MongoManager
  class Executor
    def initialize(**opts)
      @options = opts

      unless options[:dir]
        raise ArgumentError, ':dir option must be given'
      end

      if options[:username] && !options[:password]
        raise ArgumentError, ':username and :password must be given together'
      end

      @client_log_level = :warn
      Mongo::Logger.level = client_log_level

      @common_args = []
    end

    attr_reader :options
    attr_reader :config
    attr_reader :client_log_level
    attr_reader :common_args

    def init
      FileUtils.mkdir_p(root_dir)
      create_config

      if options[:sharded]
        init_sharded
      elsif options[:replica_set]
        init_rs
      else
        init_standalone
      end
    end

    def start
      read_config

      do_start
    end

    private def do_start
      config[:db_dirs].each do |db_dir|
        cmd = config[:settings][db_dir][:start_cmd]
        Helper.spawn_mongo(*cmd)
      end
    end

    def stop
      read_config

      do_stop
    end

    private def do_stop
      pids = {}

      config[:db_dirs].each do |db_dir|
        binary_basename = File.basename(config[:settings][db_dir][:start_cmd].first)
        pid_file_path = File.join(db_dir, "#{binary_basename}.pid")
        if File.exist?(pid_file_path)
          pid = File.read(pid_file_path).strip.to_i
          puts("Sending TERM to pid #{pid} for #{db_dir}")
          begin
            Process.kill('TERM', pid)
          rescue Errno::ESRCH
            # No such process
          else
            pids[db_dir] = pid
          end
        end
      end

      pids.each do |db_dir, pid|
        binary_basename = File.basename(config[:settings][db_dir][:start_cmd].first)
        Helper.wait_for_pid(db_dir, pid, 15, binary_basename)
      end
    end

    private

    def create_config
      if options[:sharded]
        @config = {
          db_dirs: [
            root_dir.join('csrs').to_s,
            root_dir.join('shard1').to_s,
            root_dir.join('s1').to_s,
          ],
        }
      elsif options[:replica_set]
        @config = {
          db_dirs: 1.upto(options[:nodes] || 3).map do |i|
            root_dir.join("rs#{i}").to_s
          end,
        }
      else
        @config = {
          db_dirs: [root_dir.to_s],
        }
      end
      write_config
    end

    def write_config
      File.open(root_dir.join('mongo-manager.yml'), 'w') do |f|
        f << YAML.dump(config)
      end
    end

    def read_config
      @config = YAML.load(File.read(File.join(root_dir, 'mongo-manager.yml')))
    end

    def init_standalone
      cmd = [
        mongo_path('mongod'),
        root_dir.join('mongod.log').to_s,
        root_dir.join('mongod.pid').to_s,
        '--dbpath', root_dir.to_s,
      ]
      Helper.spawn_mongo(*cmd)
      record_start_command(root_dir, cmd)

      if options[:username]
        client = Mongo::Client.new(['localhost:27017'],
          connect: :direct,
          database: 'admin')
        create_user(client)
        client.close

        do_stop

        cmd << '--auth'

        Helper.spawn_mongo(*cmd)
      end

      record_start_command(root_dir, cmd)
      write_config
    end

    def init_rs
      maybe_create_key

      1.upto(options[:nodes] || 3) do |i|
        port = 27016 + i
        dir = root_dir.join("rs#{i}")

        spawn_replica_set_node(dir, port, options[:replica_set], common_args)
      end

      write_config

      initiate_replica_set(
        %w(localhost:27017 localhost:27018 localhost:27019),
        options[:replica_set],
      )

      puts("Waiting for replica set to initialize")
      client = Mongo::Client.new(['localhost:27017'],
        replica_set: options[:replica_set], database: 'admin')
      client.database.command(ping: 1)

      if options[:username]
        create_user(client)
        client.close

        stop
        start

        client = Mongo::Client.new(['localhost:27017'],
          replica_set: options[:replica_set], database: 'admin',
          user: options[:username], password: options[:password],
        )
        client.database.command(ping: 1)
      end

      client.close
    end

    def init_sharded
      maybe_create_key

      spawn_replica_set_node(
        root_dir.join('csrs'),
        27018,
        'csrs',
        common_args + %w(--configsvr),
      )

      initiate_replica_set(%w(localhost:27018), 'csrs', configsvr: true)

      spawn_replica_set_node(
        root_dir.join('shard1'),
        27019,
        'shard1',
        common_args + %w(--shardsvr),
      )

      initiate_replica_set(%w(localhost:27019), 'shard1')

      port = 27017
      dir = root_dir.join('s1')
      puts("Spawn mongos on port #{port}")
      FileUtils.mkdir(dir)
      cmd = [
        mongo_path('mongos'),
        dir.join('mongos.log').to_s,
        dir.join('mongos.pid').to_s,
        '--port', port.to_s,
        '--configdb', "csrs/localhost:27018",
      ] + common_args
      Helper.spawn_mongo(*cmd)
      record_start_command(dir, cmd)

      write_config

      client = Mongo::Client.new(['localhost:27017'], database: 'admin')
      client.database.command(
        addShard: "shard1/localhost:27019",
      )

      if options[:username]
        create_user(client)
      end

      client.close
    end

    def initiate_replica_set(hosts, replica_set_name, **opts)
      members = []
      hosts.each_with_index do |host, index|
        members << { _id: index, host: host }
      end

      rs_config = {
        _id: replica_set_name,
        members: members,
      }.update(opts)

      puts("Initiating replica set #{replica_set_name}/#{hosts.join(',')}")
      client = Mongo::Client.new([hosts.first], connect: :direct)
      begin
        client.database.command(replSetInitiate: rs_config)
      ensure
        client.close
      end
    end

    def maybe_create_key
      if options[:username]
        key_file_path = root_dir.join('.key')
        Helper.create_key(key_file_path)
        @common_args += ['--keyFile', key_file_path.to_s]
      end
    end

    def create_user(client)
      client.database.users.create(
        options[:username],
        password: options[:password],
        roles: %w(root),
      )
    end

    def root_dir
      @root_dir ||= Pathname.new(options[:dir]).freeze
    end

    def mongo_path(binary)
      if options[:bin_dir]
        File.join(options[:bin_dir], binary)
      else
        binary
      end
    end

    def spawn_replica_set_node(dir, port, replica_set_name, args)
      puts("Spawn mongod on port #{port}")
      FileUtils.mkdir(dir)
      cmd = [
        mongo_path('mongod'),
        dir.join('mongod.log').to_s,
        dir.join('mongod.pid').to_s,
        '--dbpath', dir.to_s,
        '--port', port.to_s,
        '--replSet', replica_set_name,
      ] + args
      Helper.spawn_mongo(*cmd)
      record_start_command(dir, cmd)
    end

    def record_start_command(dir, cmd)
      config[:settings] ||= {}
      config[:settings][dir.to_s] ||= {}
      config[:settings][dir.to_s][:start_cmd] = cmd
    end
  end
end
