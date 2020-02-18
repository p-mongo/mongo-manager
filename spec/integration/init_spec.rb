require 'spec_helper'

describe 'init' do
  let(:executor) do
    MongoManager::Executor.new(options)
  end

  let(:client_options) do
    {server_selection_timeout: 5}
  end

  let(:client) do
    Mongo::Client.new(['localhost:27017'], client_options)
  end

  context 'single' do
    let(:options) do
      {
        dir: '/tmp/db',
      }
    end

    it 'starts' do
      executor.init

      client.database.command(ping: 1)
      client.cluster.topology.class.name.should =~ /Single/
    end
  end

  context 'replica set' do
    let(:options) do
      {
        dir: '/tmp/db',
        replica_set: 'foo',
      }
    end

    it 'starts' do
      executor.init

      client.database.command(ping: 1)
      client.cluster.topology.class.name.should =~ /ReplicaSet/
    end
  end
end
