require 'rspec/expectations'

require 'mongo_manager'

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :should
  end
end
