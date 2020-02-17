require 'optparse'
require 'mongo_manager'

module MongoManager
  class Main
    def initialize
      @global_options = {}
    end

    attr_reader :global_options

    def run
      parser = OptionParser.new do |opts|
        opts.on('--dir DIR', String, 'Path to deployment')
      end.order!(into: global_options)

      command = ARGV.shift

      if command.nil?
        usage('no command given')
      end

      commands = %w(init)
      if commands.include?(command)
        send(command)
      else
        usage("unknown command: #{command}")
      end
    end

    def usage(msg)
      raise msg
    end

    def init
      Executor.new(**global_options).init
    end

    class << self
      def run
        new.run
      end
    end
  end
end
