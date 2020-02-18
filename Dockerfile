FROM debian:9

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y ruby ruby-bundler ruby-dev make gcc

COPY Gemfile .
COPY *.gemspec .

RUN bundle install

COPY . .

CMD bundle exec rspec
