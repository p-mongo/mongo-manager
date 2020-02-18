FROM debian:9

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y ruby ruby-bundler ruby-dev make gcc curl

RUN curl -fLo mongodb-linux-x86_64-enterprise-debian92-4.2.3.tgz https://downloads.mongodb.com/linux/mongodb-linux-x86_64-enterprise-debian92-4.2.3.tgz
RUN tar xf mongodb-linux-x86_64-enterprise-debian92-4.2.3.tgz
RUN mv mongo*/ /opt/mongodb

RUN apt-get install -y libsnmp30 procps

ENV PATH=/opt/mongodb/bin:$PATH

COPY Gemfile .
COPY *.gemspec .

RUN bundle install

COPY . .

CMD bundle exec rspec
