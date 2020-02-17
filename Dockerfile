FROM ruby:2.7

COPY Gemfile .
COPY *.gemspec .

RUN bundle install

COPY . .

RUN cat /etc/debian_version
CMD bundle exec rspec
