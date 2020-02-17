FROM ruby:2.7

COPY Gemfile .
COPY *.gemspec .

RUN bundle install

COPY . .

CMD bundle exec rspec
