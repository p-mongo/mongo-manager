require 'spec_helper'

describe 'init - cmd' do
  let(:base_client_options) do
    {server_selection_timeout: 5}
  end

  let(:client_options) do
    base_client_options
  end

  let(:client) do
    Mongo::Client.new(['localhost:27017'], client_options)
  end

  before do
    Ps.mongos.should be_empty
    Ps.mongos.should be_empty
  end

  after do
    MongoManager::Helper.spawn(['./bin/mongo-manager', 'stop', '--dir', dir])
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
      MongoManager::Helper.spawn(['./bin/mongo-manager', 'stop', '--dir', dir])
      Ps.mongod.should be_empty
    end
  end

  let(:init_and_check) do
    MongoManager::Helper.spawn(['./bin/mongo-manager', 'init', '--dir', dir] + args)

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

  context 'standalone' do
    let(:dir) { '/db/standalone' }

    let(:expected_topology) { /Single/ }

    let(:args) do
      []
    end

    it_behaves_like 'starts and stops'

    context 'with auth' do
      let(:client_options) do
        base_client_options.merge(user: 'hello', password: 'word')
      end

      let(:dir) { '/db/standalone-auth' }

      let(:args) do
        %w(--user hello --password word)
      end

      it_behaves_like 'starts and stops'
    end
  end

  context 'replica set' do
    let(:dir) { '/db/rs' }

    let(:args) do
      %w(--replica-set foo)
    end

    let(:expected_topology) { /ReplicaSet/ }

    it_behaves_like 'starts and stops'

    context 'with auth' do
      let(:client_options) do
        base_client_options.merge(
          user: 'hello', password: 'word', replica_set: 'foo',
        )
      end

      let(:dir) { '/db/rs-auth' }

      let(:args) do
        %w(--user hello --password word --replica-set foo)
      end

      it_behaves_like 'starts and stops'
    end
  end

  context 'sharded' do
    let(:dir) { '/db/shard' }

    let(:args) do
      %w(--sharded 1)
    end

    let(:expected_topology) { /Sharded/ }

    it_behaves_like 'starts and stops'

    context 'with auth' do
      let(:client_options) do
        base_client_options.merge(
          user: 'hello', password: 'word',
        )
      end

      let(:dir) { '/db/shard-auth' }

      let(:args) do
        %w(--sharded 1 --user hello --password word)
      end

      it_behaves_like 'starts and stops'
    end
  end
end
