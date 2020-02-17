require 'optparse'

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
      p global_options
      p ARGV
    end

    class << self
      def run
        new.run
      end
    end
  end
end
