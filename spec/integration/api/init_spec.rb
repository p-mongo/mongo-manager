require 'spec_helper'
require 'support/contexts/init'

describe 'init' do
  include_context 'init'

  context 'standalone' do
    let(:expected_topology) { /Single/ }

    let(:dir) { '/db/standalone' }

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
          auth_source: 'admin',
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
  end

  context 'replica set' do
    let(:expected_topology) { /ReplicaSet/ }

    let(:dir) { '/db/rs' }

    let(:options) do
      {
        dir: dir,
        replica_set: 'foo',
      }
    end

    it_behaves_like 'starts and stops'

    context 'with arbiter' do
      let(:client_options) do
        base_client_options.merge(
          replica_set: 'foo',
        )
      end

      let(:dir) { '/db/rs-arbiter' }

      let(:options) do
        {
          dir: dir,
          replica_set: 'foo',
          arbiter: true,
        }
      end

      it_behaves_like 'starts and stops'

      it 'provisions two mongod and one arbiter' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 3

        client.cluster.scan!
        client.cluster.send(:servers_list).map(&:address).map(&:seed).sort.should ==
          %w(localhost:27017 localhost:27018 localhost:27019)

        puts client.cluster.summary
        server = client.cluster.servers_list.detect { |server| server.address.port == 27017 }
        server.summary.should =~ /PRIMARY|SECONDARY/
        server = client.cluster.servers_list.detect { |server| server.address.port == 27018 }
        server.summary.should =~ /PRIMARY|SECONDARY/
        server = client.cluster.servers_list.detect { |server| server.address.port == 27019 }
        server.summary.should =~ /ARBITER/
      end
    end

    context 'with specified number of nodes' do
      let(:client_options) do
        base_client_options.merge(
          replica_set: 'foo',
        )
      end

      let(:dir) { '/db/rs-nodes' }

      let(:options) do
        {
          dir: dir,
          replica_set: 'foo',
          data_bearing_nodes: 1,
        }
      end

      it_behaves_like 'starts and stops'

      it 'provisions one mongod' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 1

        client.cluster.scan!
        client.cluster.send(:servers_list).map(&:address).map(&:seed).sort.should ==
          %w(localhost:27017)

        client.database.command(ping: 1)
      end
    end

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

        client.database.command(ping: 1)
        client.cluster.send(:servers_list).map(&:address).map(&:seed).sort.should ==
          %w(localhost:27800 localhost:27801 localhost:27802)
      end
    end
  end

  context 'sharded' do
    let(:expected_topology) { /Sharded/ }

    context ':sharded option' do
      let(:dir) { '/db/shard-sharded' }

      let(:options) do
        {
          dir: dir,
          sharded: 2,
        }
      end

      it_behaves_like 'starts and stops'

      it 'creates two shards and one mongos' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 3

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongod')
          cmdline.strip.split("\n").length.should == 1
        end
      end
    end

    context ':mongos option' do
      let(:dir) { '/db/shard-mongos' }

      let(:options) do
        {
          dir: dir,
          mongos: 2,
        }
      end

      it_behaves_like 'starts and stops'

      it 'creates one shard and two mongos' do
        executor.init

        pids = Ps.mongod
        # one config server mongod and one shard mongod
        pids.length.should == 2

        pids = Ps.mongos
        pids.length.should == 2
      end
    end

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
  end
end
