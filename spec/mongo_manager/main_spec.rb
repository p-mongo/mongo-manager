require 'spec_helper'

describe MongoManager::Main do
  describe '#run' do
    shared_examples_for 'parses arguments' do
      it 'parses arguments' do
        mock = double('executor')
        mock.should receive(expected_command)
        if expected_options.empty?
          if RUBY_VERSION < '2.7'
            MongoManager::Executor.should receive(:new).with({}).and_return(mock)
          else
            MongoManager::Executor.should receive(:new).with(no_args).and_return(mock)
          end
        else
          MongoManager::Executor.should receive(:new).with(**expected_options).and_return(mock)
        end
        described_class.new.run(cmd_args)
      end
    end

    context 'init' do
      let(:expected_command) { 'init' }

      context 'standalone' do
        let(:cmd_args) do
          %w(init)
        end

        let(:expected_options) do
          {}
        end

        it_behaves_like 'parses arguments'

        context 'dir before init' do
          let(:cmd_args) do
            %w(--dir foo init)
          end

          let(:expected_options) do
            {dir: 'foo'}
          end

          it_behaves_like 'parses arguments'
        end

        context 'dir after init' do
          let(:cmd_args) do
            %w(init --dir foo)
          end

          let(:expected_options) do
            {dir: 'foo'}
          end

          it_behaves_like 'parses arguments'
        end

        context 'auth options' do
          let(:cmd_args) do
            %w(init --user foo --password bar)
          end

          let(:expected_options) do
            {username: 'foo', password: 'bar'}
          end

          it_behaves_like 'parses arguments'
        end

        context 'port option' do
          let(:cmd_args) do
            %w(init --port 27200)
          end

          let(:expected_options) do
            {base_port: 27200}
          end

          it_behaves_like 'parses arguments'
        end

        context 'extra server option' do
          let(:cmd_args) do
            %w(init -- --setParameter enableTestCommands=1)
          end

          let(:expected_options) do
            {passthrough_args: %w(--setParameter enableTestCommands=1)}
          end

          it_behaves_like 'parses arguments'
        end
      end

      context 'replica set' do
        let(:cmd_args) do
          %w(init --replica-set foo)
        end

        let(:expected_options) do
          {replica_set: 'foo'}
        end

        it_behaves_like 'parses arguments'
      end

      context 'sharded' do
        let(:cmd_args) do
          %w(init --sharded 2)
        end

        let(:expected_options) do
          {sharded: 2}
        end

        it_behaves_like 'parses arguments'
      end

      context 'mongos' do
        let(:cmd_args) do
          %w(init --mongos 2)
        end

        let(:expected_options) do
          {mongos: 2}
        end

        it_behaves_like 'parses arguments'
      end

      context 'mongod argument passthrough' do
        let(:cmd_args) do
          %w(init --mongod-arg foo)
        end

        let(:expected_options) do
          {mongod_passthrough_args: %w(foo)}
        end

        it_behaves_like 'parses arguments'
      end

      context 'mongos argument passthrough' do
        let(:cmd_args) do
          %w(init --mongos-arg foo)
        end

        let(:expected_options) do
          {mongos_passthrough_args: %w(foo)}
        end

        it_behaves_like 'parses arguments'
      end

      context 'csrs argument' do
        let(:cmd_args) do
          %w(init --csrs 1)
        end

        let(:expected_options) do
          {csrs: 1}
        end

        it_behaves_like 'parses arguments'
      end
    end

    context 'stop' do
      let(:expected_command) { 'stop' }

      context 'dir before stop' do
        let(:cmd_args) do
          %w(--dir foo stop)
        end

        let(:expected_options) do
          {dir: 'foo'}
        end

        it_behaves_like 'parses arguments'
      end

      context 'dir after stop' do
        let(:cmd_args) do
          %w(stop --dir foo)
        end

        let(:expected_options) do
          {dir: 'foo'}
        end

        it_behaves_like 'parses arguments'
      end
    end
  end
end
