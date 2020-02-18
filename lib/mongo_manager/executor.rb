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
    end

    attr_reader :options
    attr_reader :config

    def init
      FileUtils.mkdir_p(root_dir)
      create_config

      if options[:replica_set]
        init_rs
      else
        init_single
      end
    end

    def start
      read_config
      config[:db_dirs].each do |db_dir|
        cmd = config[:settings][db_dir][:start_cmd]
        spawn_mongo(*cmd)
      end
    end

    def stop
      read_config

      pids = {}

      config[:db_dirs].each do |db_dir|
        pid_file_path = File.join(db_dir, 'mongod.pid')
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
        puts("Waiting for pid #{pid} for #{db_dir} to exit")
        # When we run the tests, the rspec process is the parent of launched
        # mongod/mongos processes, and must reap the children in order for
        # the processes to fully die.
        Thread.new do
          begin
            Process.wait(pid)
          rescue Errno::ECHLD
            # Process we are waiting for was launched by another process
            # (i.e. an earlier invocation of mongo-manager, not the rspec
            # process; ignore)
          end
        end
        allowed_time = 15
        deadline = Time.now + allowed_time
        loop do
          begin
            Process.kill(0, pid)
          rescue Errno::ESRCH
            # No such process
            break
          end
          if Time.now > deadline
            puts `ps awwxu`
            raise StopError, "Pid #{pid} for #{db_dir} did not exit after #{allowed_time} seconds"
          end
          sleep 0.1
        end
      end
    end

    private

    def create_config
      if options[:replica_set]
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

    def init_single
      spawn_mongo('mongod',
        root_dir.join('mongod.log').to_s,
        root_dir.join('mongod.pid').to_s,
        '--dbpath', root_dir.to_s,
      )

      if options[:username]
        client = Mongo::Client.new(['localhost:27017'], connect: :direct, database: 'admin')
        create_user(client)
        client.close

        stop

        spawn_mongo('mongod',
          root_dir.join('mongod.log').to_s,
          root_dir.join('mongod.pid').to_s,
          '--dbpath', root_dir.to_s,
          '--auth',
        )
      end
    end

    def init_rs
      args = []

      if options[:username]
        key_file_path = root_dir.join('.key')
        File.open(key_file_path, 'w') do |f|
          f << Base64.encode64(OpenSSL::Random.random_bytes(756))
        end
        FileUtils.chmod(0600, key_file_path)
        args += ['--keyFile', key_file_path.to_s]
      end

      1.upto(options[:nodes] || 3) do |i|
        port = 27016 + i
        dir = root_dir.join("rs#{i}")

        spawn_rs_node(dir, port, options[:replica_set], args)
      end

      write_config

      initiate_replica_set(
        %w(localhost:27017 localhost:27018 localhost:27019),
        options[:replica_set],
      )

      puts("Waiting for replica set to initialize")
      client = Mongo::Client.new(['localhost:27017'], replica_set: options[:replica_set], database: 'admin')
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

    def initiate_replica_set(hosts, replica_set_name)
      members = []
      hosts.each_with_index do |host, index|
        members << { _id: index, host: host }
      end

      rs_config = {
        _id: replica_set_name,
        members: members,
      }

      puts("Initiating replica set #{replica_set_name}/#{hosts.join(',')}")
      client = Mongo::Client.new([hosts.first], connect: :direct)
      begin
        client.database.command(replSetInitiate: rs_config)
      ensure
        client.close
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
      Pathname.new(options[:dir])
    end

    def mongo_path(binary)
      if options[:bin_dir]
        File.join(options[:bin_dir], binary)
      else
        binary
      end
    end

    def spawn(*cmd)
      if pid = fork
        Process.wait(pid)
        if $?.exitstatus != 0
          raise SpawnError, "Exited with code #{$?.exitstatus}"
        end
      else
        exec(*cmd)
      end
    end

    def join_command(cmd)
      cmd.map { |part| "'" + part.gsub("'", "\\'") + "'" }.join(' ')
    end

    def spawn_mongo(bin_basename, log_path, pid_file_path, *args)
      bin_path = mongo_path(bin_basename)
      expanded_cmd = [
        bin_path,
        '--logpath', log_path,
        '--pidfilepath', pid_file_path,
        '--fork',
      ] + args
      puts("Execute #{join_command(expanded_cmd)}")
      spawn(*expanded_cmd)
    rescue SpawnError => e
      if File.exist?(log_path)
        lines = File.read(log_path).split("\n")
        start = [20, lines.length].min
        if start > 0
          lines = lines[-start..-1]
          extra = "last 20 log lines from #{log_path}:\n#{lines.join("\n")}"
          raise SpawnError, "#{e}; #{extra}"
        else
          raise SpawnError, "#{e}; log file #{log_path} empty"
        end
      else
        extra = "log file #{log_path} does not exist"
        if File.exist?(dir = File.dirname(log_path))
          extra << "; directory #{dir} exists"
        else
          extra << "; directory #{dir} does not exist either"
        end
        raise SpawnError, "#{e}; #{extra}"
      end
    end

    def spawn_rs_node(dir, port, replica_set_name, args)
      puts("Spawn mongod on port #{port}")
      FileUtils.mkdir(dir)
      cmd = [
        'mongod',
        dir.join('mongod.log').to_s,
        dir.join('mongod.pid').to_s,
        '--dbpath', dir.to_s,
        '--port', port.to_s,
        '--replSet', replica_set_name,
      ] + args
      spawn_mongo(*cmd)
      config[:settings] ||= {}
      config[:settings][dir.to_s] ||= {}
      config[:settings][dir.to_s][:start_cmd] = cmd
    end
  end
end
