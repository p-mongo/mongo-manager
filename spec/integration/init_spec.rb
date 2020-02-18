require 'spec_helper'

describe 'init' do
  let(:executor) do
    MongoManager::Executor.new(options)
  end

  let(:base_client_options) do
    {server_selection_timeout: 5}
  end

  let(:client_options) do
    base_client_options
  end

  let(:client) do
    Mongo::Client.new(['localhost:27017'], client_options)
  end

  after do
    executor.stop #rescue nil
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

  context 'single' do
    let(:dir) { '/db/single' }

    let(:options) do
      {
        dir: dir,
      }
    end

    let(:init_and_check) do
      executor.init

      client.database.command(ping: 1)
      client.cluster.topology.class.name.should =~ /Single/
      client.close
    end

    it_behaves_like 'starts and stops'

    context 'with auth' do
      let(:client_options) do
        base_client_options.merge(user: 'hello', password: 'word')
      end

      let(:dir) { '/db/single-auth' }

      let(:options) do
        {
          dir: dir,
          username: 'hello',
          password: 'word',
        }
      end

      it_behaves_like 'starts and stops'
    end
  end

  context 'replica set' do
    let(:dir) { '/db/rs' }

    let(:options) do
      {
        dir: dir,
        replica_set: 'foo',
      }
    end

    let(:init_and_check) do
      executor.init

      client.database.command(ping: 1)
      client.cluster.topology.class.name.should =~ /ReplicaSet/
      client.close
    end

    it_behaves_like 'starts and stops'
  end
end
