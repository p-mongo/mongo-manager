require 'optparse'

module MongoManager
  class Main

    def run
      params = {}
      parser = OptionParser.new do |opts|
        opts.on('--dir DIR', String)
      end.order!(into: params)
      p params
      p ARGV
    end

    class << self
      def run
        new.run
      end
    end
  end
end
