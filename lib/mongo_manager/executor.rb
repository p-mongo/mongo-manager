module MongoManager
  class Executor
    def initialize(**opts)
      @options = opts
    end

    attr_reader :options

    def init
    end
  end
end
