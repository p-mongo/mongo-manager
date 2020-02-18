require 'fileutils'
require 'pathname'

module MongoManager
  class Executor
    def initialize(**opts)
      @options = opts

      unless options[:dir]
        raise ArgumentError, ':dir option must be given'
      end
    end

    attr_reader :options

    def init
      FileUtils.mkdir_p(root_dir)

      if options[:replica_set]
        init_rs
      else
        init_single
      end
    end

    def init_single
      spawn(mongo_path('mongod'),
        '--dbpath', root_dir.to_s,
        '--fork',
        '--logpath', root_dir.join('mongod.log').to_s,
      )
    end

    def init_rs
      1.upto(options[:nodes] || 3) do |i|
        port = 27016 + i

        puts("Spawn mongod on port #{port}")
        dir = root_dir.join("rs#{i}")
        FileUtils.mkdir(dir)
        spawn_mongo('mongod', dir.join('mongod.log').to_s,
          '--dbpath', dir.to_s,
          '--fork',
          '--port', port.to_s,
          '--replSet', options[:replica_set],
        )
      end

      client = Mongo::Client.new(['localhost:27017'], connect: :direct)

      rs_config = {
        _id: options[:replica_set],
        members: [
          { _id: 0, host: 'localhost:27017' },
          { _id: 1, host: 'localhost:27018' },
          { _id: 2, host: 'localhost:27019' },
        ],
      }

      puts("Initiating replica set")
      client.database.command(replSetInitiate: rs_config)
      client.close

      puts("Waiting for replica set to initialize")
      client = Mongo::Client.new(['localhost:27017'], replica_set: options[:replica_set])
      client.database.command(ping: 1)
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

    def spawn_mongo(bin_basename, log_path, *args)
      bin_path = mongo_path(bin_basename)
      expanded_cmd = [bin_path, '--logpath', log_path] + args
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
  end
end
