shared_context 'init' do
  let(:executor) do
    MongoManager::Executor.new(options)
  end

  let(:base_client_options) do
    {server_selection_timeout: 5}
  end

  let(:client_options) do
    base_client_options
  end

  let(:client_addresses) do
    ['localhost:27017']
  end

  let(:client) do
    Mongo::Client.new(client_addresses, client_options)
  end

  before do
    Ps.mongos.should be_empty
    Ps.mongos.should be_empty
  end

  after do
    executor.stop #rescue nil
    Ps.mongos.should be_empty
    Ps.mongos.should be_empty
    FileUtils.rm_rf(dir)
  end

  shared_examples_for 'starts and stops' do
    it 'starts' do
      init_and_check
    end

    it 'stops' do
      init_and_check
      Ps.mongod.should_not be_empty
      executor.stop
      Ps.mongod.should be_empty
    end
  end

  let(:init_and_check) do
    executor.init

    # Wait for topology to be discovered
    client.database.command(ping: 1)

    # Assert topology is as expected
    client.cluster.topology.class.name.should =~ expected_topology

    # Ensure deployment is writable - admin db
    client.use('admin')['foo'].insert_one(test: 1)

    # In a sharded cluster admin db is writable even when no shards are defined,
    # use a non-admin db to catch the condition of no shards being defined
    client.use('test')['foo'].insert_one(test: 1)

    client.close
  end
end
