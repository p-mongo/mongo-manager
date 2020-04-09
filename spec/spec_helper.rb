require 'rspec/expectations'
require 'rspec/mocks'
require 'fileutils'
autoload :Byebug, 'byebug'

require 'mongo_manager'
require 'mongo_manager/main'

require 'support/ps'
require 'support/utils'

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :should
  end
end
