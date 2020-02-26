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

        opts.on('--sharded NUM', Integer, 'Create a sharded cluster with NUM shards') do |v|
          unless v.to_i > 0
            usage("invalid --sharded value: #{v}")
          end
          options[:sharded] = v.to_i
        end

        opts.on('--mongos NUM', Integer, 'Create a sharded cluster with NUM mongos') do |v|
          unless v.to_i > 0
            usage("invalid --mongos value: #{v}")
          end
          options[:mongos] = v.to_i
        end

        opts.on('--csrs NUM', Integer, 'Use a config server replica set with NUM nodes') do |v|
          unless v.to_i > 0
            usage("invalid --csrs value: #{v}")
          end
          options[:csrs] = v.to_i
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

        opts.on('--tls-mode MODE', String, 'Enable TLS and specify TLS mode to pass to mongod/mongos') do |v|
          options[:tls_mode] = v
        end

        opts.on('--tls-certificate-key-file PATH', String, 'Path to client certificate') do |v|
          options[:tls_certificate_key_file] = v
        end

        opts.on('--tls-ca-file PATH', String, 'Path to CA certificate') do |v|
          options[:tls_ca_file] = v
        end

        opts.on('--mongod-arg ARG', String, 'Pass an argument to non-config server mongod') do |v|
          options[:mongod_passthrough_args] ||= []
          options[:mongod_passthrough_args] << v
        end

        opts.on('--cs-arg ARG', String, 'Pass an argument to config server mongod') do |v|
          options[:config_server_passthrough_args] ||= []
          options[:config_server_passthrough_args] << v
        end

        opts.on('--mongos-arg ARG', String, 'Pass an argument to mongos') do |v|
          options[:mongos_passthrough_args] ||= []
          options[:mongos_passthrough_args] << v
        end
      end.order!(argv)

      unless argv.empty?
        options[:passthrough_args] = argv
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
