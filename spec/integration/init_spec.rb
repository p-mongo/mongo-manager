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

  after do
    executor.stop rescue nil
  end

  context 'single' do
    let(:options) do
      {
        dir: '/tmp/db',
      }
    end

    let(:init_and_check) do
      executor.init

      client.database.command(ping: 1)
      client.cluster.topology.class.name.should =~ /Single/
      client.close
    end

    it 'starts' do
      init_and_check
    end

    it 'stops' do
      init_and_check
      executor.stop
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
      client.close
    end
  end
end
