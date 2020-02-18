module MongoManager
  class Error < StandardError
  end

  class SpawnError < Error
  end

  class StopError < Error
  end
end
