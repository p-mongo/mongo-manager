require 'spec_helper'
require 'support/contexts/init'

describe 'init' do
  include_context 'init'

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

      it 'uses a standalone for config server' do
        executor.init

        client = Mongo::Client.new(['localhost:27018'])
        client.cluster.topology.class.name.should =~ /Single/
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

    context 'extra server option' do
      let(:dir) { '/db/shard-extra-option' }

      let(:options) do
        {
          dir: dir,
          sharded: 1,
          passthrough_args: %w(--setParameter enableTestCommands=1),
        }
      end

      it 'passes the option' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 2

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongod')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--setParameter enableTestCommands=1')

          cmdline.scan(/--setParameter enableTestCommands=1/).length.should == 1
        end

        pids = Ps.mongos
        pids.length.should == 1

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongos')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--setParameter enableTestCommands=1')

          cmdline.scan(/--setParameter enableTestCommands=1/).length.should == 1
        end
      end
    end

    context 'mongod and mongos passthrough' do
      let(:dir) { '/db/shard-mongod-mongos-passthrough' }

      let(:options) do
        {
          dir: dir,
          sharded: 1,
          mongod_passthrough_args: %w(--nounixsocket),
          mongos_passthrough_args: %w(--httpinterface),
        }
      end

      it 'passes the arguments' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 2

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongod')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--nounixsocket')
          cmdline.should_not include('--httpinterface')
        end

        pids = Ps.mongos
        pids.length.should == 1

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongos')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--httpinterface')
          cmdline.should_not include('--nounixsocket')
        end
      end
    end

    context 'tls' do
      let(:dir) { '/db/sharded-tls' }

      let(:options) do
        {
          dir: dir,
          sharded: 1,
          tls_mode: 'requireTLS',
          tls_certificate_key_file: 'spec/support/certificates/server.pem',
          tls_ca_file: 'spec/support/certificates/ca.crt',
        }
      end

      let(:client_options) do
        base_client_options.merge(
          ssl: true,
          ssl_cert: 'spec/support/certificates/server.pem',
          ssl_key: 'spec/support/certificates/server.pem',
          ssl_ca_cert: 'spec/support/certificates/ca.crt',
        )
      end

      it_behaves_like 'starts and stops'

      it 'passes the arguments' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 2

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongod')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--sslMode requireSSL')
          cmdline.should include('--sslPEMKeyFile spec/support/certificates/server.pem')
          cmdline.should include('--sslCAFile spec/support/certificates/ca.crt')
        end

        pids = Ps.mongos
        pids.length.should == 1

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongos')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--sslMode requireSSL')
          cmdline.should include('--sslPEMKeyFile spec/support/certificates/server.pem')
          cmdline.should include('--sslCAFile spec/support/certificates/ca.crt')
        end
      end
    end
  end
end
