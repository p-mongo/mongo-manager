require 'spec_helper'

describe 'init' do
  let(:executor) do
    MongoManager::Executor.new(options)
  end

  context 'single' do
    let(:options) do
      {
        dir: '/tmp/db',
      }
    end

    it 'starts' do
      executor.init
    end
  end
end
