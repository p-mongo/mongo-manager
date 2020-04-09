source 'https://rubygems.org'

gemspec

group :development do
  gem 'rake'
end

group :test do
  gem 'rspec-core'
  gem 'rspec-expectations'
  gem 'rspec-mocks'
  gem 'rfc'
  if RUBY_VERSION < '2.4'
    gem 'byebug', '~> 10'
  else
    gem 'byebug'
  end
end

gem 'mongo', git: 'https://github.com/mongodb/mongo-ruby-driver'
