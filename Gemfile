source 'https://rubygems.org'

gemspec

group :development do
  gem 'rake'
end

group :test do
  gem 'rspec-core'
  gem 'rspec-expectations'
  gem 'rfc'
  if RUBY_VERSION < '2.4'
    gem 'byebug', '~> 10'
  else
    gem 'byebug'
  end
end
