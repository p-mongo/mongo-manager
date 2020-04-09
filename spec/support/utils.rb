module Utils
  module_function def server_type(port)
    client = Mongo::Client.new(["localhost:#{port}"], server_selection_timeout: 5)
    client.cluster.next_primary.description.server_type.tap do
      client.close
    end
  end
end
