require 'spec_helper'

describe MongoManager::Main do
  describe '#run' do
    shared_examples_for 'parses arguments' do
      it 'parses arguments' do
        mock = double('executor')
        mock.should receive(expected_command)
        if expected_options.empty?
          MongoManager::Executor.should receive(:new).with(no_args).and_return(mock)
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
