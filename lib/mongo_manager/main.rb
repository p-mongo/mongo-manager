require 'optparse'
require 'mongo_manager'

module MongoManager
  class Main
    def initialize
      @global_options = {}
    end

    attr_reader :global_options

    def run(argv = ARGV)
      argv = argv.dup

      parser = OptionParser.new do |opts|
        configure_global_options(opts)
      end.order!(argv)

      command = argv.shift

      if command.nil?
        usage('no command given')
      end

      commands = %w(init stop)
      if commands.include?(command)
        send(command, argv)
      else
        usage("unknown command: #{command}")
      end
    end

    def usage(msg)
      raise msg
    end

    def init(argv)
      options = {}
      parser = OptionParser.new do |opts|
        configure_global_options(opts)

        opts.on('--replica-set NAME', String, 'Create a replica set with the specified NAME') do |v|
          options[:replica_set] = v
        end

        opts.on('--sharded SHARDS', Integer, 'Create a sharded cluster with SHARDS shards') do |v|
          unless v.to_i > 0
            usage("invalid --sharded value: #{v}")
          end
          options[:sharded] = v.to_i
        end

        opts.on('--bin-dir DIR', String, 'Path to mongod/mongos binaries') do |v|
          options[:bin_dir] = v
        end

        opts.on('--port PORT', Integer, 'Base port to use for deployment') do |v|
          unless v.to_i > 0
            usage("invalid --port value: #{v}")
          end
          options[:base_port] = v
        end

        opts.on('--user USER', String, 'Enable auth, add USER as a root user') do |v|
          options[:username] = v
        end

        opts.on('--password PASS', String, 'Specify password for the user defined with --user') do |v|
          options[:password] = v
        end
      end.order!(argv)

      unless argv.empty?
        usage("bogus arguments: #{argv.join(' ')}")
      end

      Executor.new(**global_options.merge(options)).init
    end

    def stop(argv)
      options = {}
      parser = OptionParser.new do |opts|
        configure_global_options(opts)
      end.order!(argv)

      unless argv.empty?
        usage("bogus arguments: #{argv.join(' ')}")
      end

      Executor.new(**global_options.merge(options)).stop
    end

    private

    def configure_global_options(opts)
      opts.on('--dir DIR', String, 'Path to deployment') do |v|
        global_options[:dir] = v
      end
    end

    class << self
      def run
        new.run
      end
    end
  end
end
