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

  context 'standalone' do
    let(:dir) { '/db/standalone' }

    let(:expected_topology) { /Single/ }

    let(:options) do
      {
        dir: dir,
      }
    end

    it_behaves_like 'starts and stops'

    context 'with auth' do
      let(:client_options) do
        base_client_options.merge(user: 'hello', password: 'word')
      end

      let(:dir) { '/db/standalone-auth' }

      let(:options) do
        {
          dir: dir,
          username: 'hello',
          password: 'word',
        }
      end

      it_behaves_like 'starts and stops'
    end

    context 'when base port is overridden' do
      let(:dir) { '/db/standalone-port' }

      let(:options) do
        {
          dir: dir,
          base_port: 27800,
        }
      end

      let(:client_addresses) do
        ['localhost:27800']
      end

      it_behaves_like 'starts and stops'
    end

    context 'extra server option' do
      let(:dir) { '/db/standalone-extra-option' }

      let(:options) do
        {
          dir: dir,
          passthrough_args: %w(--setParameter enableTestCommands=1)
        }
      end

      it 'passes the option' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 1
        cmdline = `ps awwxu |grep #{pids.first} |grep -v grep |grep mongod`
        cmdline.strip.split("\n").length.should == 1
        cmdline.should include('--setParameter enableTestCommands=1')
      end
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

    let(:expected_topology) { /ReplicaSet/ }

    it_behaves_like 'starts and stops'

    context 'with auth' do
      let(:client_options) do
        base_client_options.merge(
          user: 'hello', password: 'word', replica_set: 'foo',
        )
      end

      let(:dir) { '/db/rs-auth' }

      let(:options) do
        {
          dir: dir,
          username: 'hello',
          password: 'word',
          replica_set: 'foo',
        }
      end

      it_behaves_like 'starts and stops'
    end

    context 'when base port is overridden' do
      let(:dir) { '/db/rs-port' }

      let(:options) do
        {
          dir: dir,
          replica_set: 'foo',
          base_port: 27800,
        }
      end

      let(:client_addresses) do
        ['localhost:27800']
      end

      it_behaves_like 'starts and stops'

      it 'uses correct ports' do
        executor.init

        client.cluster.scan!
        client.cluster.servers.map(&:address).map(&:seed).sort.should ==
          %w(localhost:27800 localhost:27801 localhost:27802)
      end
    end

    context 'extra server option' do
      let(:dir) { '/db/rs-extra-option' }

      let(:options) do
        {
          dir: dir,
          replica_set: 'foo',
          passthrough_args: %w(--setParameter enableTestCommands=1)
        }
      end

      it 'passes the option' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 3

        pids.each do |pid|
          cmdline = `ps awwxu |grep #{pid} |grep -v grep |grep mongod`
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--setParameter enableTestCommands=1')
        end
      end
    end
  end

  context 'sharded' do
    let(:dir) { '/db/shard' }

    let(:options) do
      {
        dir: dir,
        sharded: 1,
      }
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

      let(:options) do
        {
          dir: dir,
          username: 'hello',
          password: 'word',
          sharded: 1,
        }
      end

      it_behaves_like 'starts and stops'
    end

    context 'when base port is overridden' do
      let(:dir) { '/db/shard-port' }

      let(:options) do
        {
          dir: dir,
          sharded: 1,
          base_port: 27800,
        }
      end

      let(:client_addresses) do
        ['localhost:27800']
      end

      it_behaves_like 'starts and stops'
    end

    context 'extra server option' do
      let(:dir) { '/db/shard-extra-option' }

      let(:options) do
        {
          dir: dir,
          sharded: 1,
          passthrough_args: %w(--setParameter enableTestCommands=1)
        }
      end

      it 'passes the option' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 2

        pids.each do |pid|
          cmdline = `ps awwxu |grep #{pid} |grep -v grep |grep mongod`
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--setParameter enableTestCommands=1')
        end

        pids = Ps.mongos
        pids.length.should == 1

        pids.each do |pid|
          cmdline = `ps awwxu |grep #{pid} |grep -v grep |grep mongos`
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--setParameter enableTestCommands=1')
        end
      end
    end
  end
end
