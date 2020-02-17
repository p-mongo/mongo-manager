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
      spawn(mongo_path('mongod'), '--dbpath', root_dir.to_s)
    end

    def root_dir
      Pathname.new(options[:dir])
    end

    def mongo_path(binary)
      if options[:binarypath]
        File.join(options[:binarypath], binary)
      else
        binary
      end
    end

    def spawn(*cmd)
      if pid = fork
        Process.wait(pid)
        if $?.exitstatus != 0
          raise "Exited with code #{$?.exitstatus}"
        end
      else
        exec(*cmd)
      end
    end
  end
end
