require 'spec_helper'
require 'support/contexts/init'

describe 'init' do
  include_context 'init'

  context 'standalone' do
    let(:expected_topology) { /Single/ }

    let(:dir) { '/db/standalone' }

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
        pid = pids.first

        cmdline = Ps.get_cmdline(pid, 'mongod')
        cmdline.strip.split("\n").length.should == 1
        cmdline.should include('--setParameter enableTestCommands=1')

        cmdline.scan(/--setParameter enableTestCommands=1/).length.should == 1
      end
    end

    context 'mongod passthrough' do
      let(:dir) { '/db/standalone-mongod-passthrough' }

      let(:options) do
        {
          dir: dir,
          mongod_passthrough_args: %w(--setParameter diagnosticDataCollectionEnabled=false),
        }
      end

      it 'passes the arguments' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 1
        pid = pids.first

        cmdline = Ps.get_cmdline(pid, 'mongod')
        cmdline.strip.split("\n").length.should == 1
        cmdline.should include('--setParameter diagnosticDataCollectionEnabled=false')
      end
    end

    context 'tls' do
      let(:dir) { '/db/standalone-tls' }

      let(:options) do
        {
          dir: dir,
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
        pids.length.should == 1
        pid = pids.first

        cmdline = Ps.get_cmdline(pid, 'mongod')
        cmdline.strip.split("\n").length.should == 1
        cmdline.should include('--tlsMode requireTLS')
        cmdline.should include('--tlsCertificateKeyFile spec/support/certificates/server.pem')
        cmdline.should include('--tlsCAFile spec/support/certificates/ca.crt')
      end

      context 'with legacy option names' do
        let(:dir) { '/db/standalone-tls-legacy' }

        let(:options) do
          {
            dir: dir,
            bin_dir: '/opt/mongodb/4.0/bin',
            tls_mode: 'requireTLS',
            tls_certificate_key_file: 'spec/support/certificates/server.pem',
            tls_ca_file: 'spec/support/certificates/ca.crt',
          }
        end

        it_behaves_like 'starts and stops'

        it 'passes the arguments' do
          executor.init

          pids = Ps.mongod
          pids.length.should == 1
          pid = pids.first

          cmdline = Ps.get_cmdline(pid, 'mongod')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--sslMode requireSSL')
          cmdline.should include('--sslPEMKeyFile spec/support/certificates/server.pem')
          cmdline.should include('--sslCAFile spec/support/certificates/ca.crt')
        end
      end
    end

    context 'mmapv1' do
      let(:dir) { '/db/standalone-mmapv1' }

      let(:options) do
        {
          dir: dir,
          bin_dir: '/opt/mongodb/4.0/bin',
          mongod_passthrough_args: %w(--storageEngine=mmapv1),
        }
      end

      it_behaves_like 'starts and stops'
    end
  end

  context 'replica set' do
    let(:expected_topology) { /ReplicaSet/ }

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
          cmdline = Ps.get_cmdline(pid, 'mongod')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--setParameter enableTestCommands=1')

          cmdline.scan(/--setParameter enableTestCommands=1/).length.should == 1
        end
      end
    end

    context 'mongod passthrough' do
      let(:dir) { '/db/rs-mongod-passthrough' }

      let(:options) do
        {
          dir: dir,
          replica_set: 'foo',
          mongod_passthrough_args: %w(--setParameter diagnosticDataCollectionEnabled=false),
        }
      end

      it 'passes the arguments' do
        executor.init

        pids = Ps.mongod
        pids.length.should == 3

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongod')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--setParameter diagnosticDataCollectionEnabled=false')
        end
      end
    end

    context 'tls' do
      let(:dir) { '/db/rs-tls' }

      let(:options) do
        {
          dir: dir,
          replica_set: 'foo',
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
        pids.length.should == 3

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongod')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--tlsMode requireTLS')
          cmdline.should include('--tlsCertificateKeyFile spec/support/certificates/server.pem')
          cmdline.should include('--tlsCAFile spec/support/certificates/ca.crt')
        end
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

      it 'uses a replica set for config server' do
        executor.init

        client = Mongo::Client.new(['localhost:27018'])
        client.cluster.topology.class.name.should =~ /ReplicaSet/
      end
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
          mongod_passthrough_args: %w(--setParameter diagnosticDataCollectionEnabled=false),
          mongos_passthrough_args: %w(--setParameter enableTestCommands=1),
          config_server_passthrough_args: %w(--logappend),
        }
      end

      it 'passes the arguments' do
        executor.init

        pids = Ps.mongod.sort
        pids.length.should == 2

        # config server
        pid = pids.shift
        cmdline = Ps.get_cmdline(pid, 'mongod')
        cmdline.strip.split("\n").length.should == 1
        cmdline.should include('--logappend')
        cmdline.should_not include('--setParameter diagnosticDataCollectionEnabled=false')
        cmdline.should_not include('--setParameter enableTestCommands=1')

        # shard node
        pid = pids.shift
        cmdline = Ps.get_cmdline(pid, 'mongod')
        cmdline.strip.split("\n").length.should == 1
        cmdline.should include('--setParameter diagnosticDataCollectionEnabled=false')
        cmdline.should_not include('--setParameter enableTestCommands=1')
        cmdline.should_not include('--logappend')

        pids = Ps.mongos
        pids.length.should == 1

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongos')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--setParameter enableTestCommands=1')
          cmdline.should_not include('--setParameter diagnosticDataCollectionEnabled=false')
          cmdline.should_not include('--logappend')
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
          cmdline.should include('--tlsMode requireTLS')
          cmdline.should include('--tlsCertificateKeyFile spec/support/certificates/server.pem')
          cmdline.should include('--tlsCAFile spec/support/certificates/ca.crt')
        end

        pids = Ps.mongos
        pids.length.should == 1

        pids.each do |pid|
          cmdline = Ps.get_cmdline(pid, 'mongos')
          cmdline.strip.split("\n").length.should == 1
          cmdline.should include('--tlsMode requireTLS')
          cmdline.should include('--tlsCertificateKeyFile spec/support/certificates/server.pem')
          cmdline.should include('--tlsCAFile spec/support/certificates/ca.crt')
        end
      end
    end

    context 'mmapv1' do
      let(:dir) { '/tmp/sharded-mmapv1' }

      let(:options) do
        {
          dir: dir,
          sharded: 1,
          bin_dir: '/opt/mongodb/4.0/bin',
          mongod_passthrough_args: %w(--storageEngine=mmapv1 --smallfiles --noprealloc),
        }
      end

      let(:client_options) do
        base_client_options.merge(
          retry_reads: false, retry_writes: false,
        )
      end

      it_behaves_like 'starts and stops'
    end

    context 'sharded replica set' do
      let(:dir) { '/tmp/sharded-rs' }

      let(:options) do
        {
          dir: dir,
          sharded: 1,
          replica_set: 'foo',
          data_bearing_nodes: 3,
        }
      end

      it_behaves_like 'starts and stops'

      it 'creates the proper number of servers' do
        executor.init

        Utils.server_type(27017).should == :sharded
        %i(primary secondary).should include(Utils.server_type(27018))
        %i(primary secondary).should include(Utils.server_type(27019))
        %i(primary secondary).should include(Utils.server_type(27020))
        Utils.server_type(27021).should == :primary
      end
    end
  end
end
