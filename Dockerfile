FROM debian:9

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y ruby ruby-bundler ruby-dev make gcc curl libsnmp30 procps

RUN mkdir /opt/mongodb

RUN curl -fLo mongodb-linux-x86_64-enterprise-debian92-4.2.3.tgz \
  https://downloads.mongodb.com/linux/mongodb-linux-x86_64-enterprise-debian92-4.2.3.tgz
RUN tar xf mongodb-linux-x86_64-enterprise-debian92-4.2.3.tgz
RUN mv mongo*/ /opt/mongodb/4.2

RUN curl -fLo mongodb-linux-x86_64-enterprise-debian92-4.0.16.tgz \
  https://downloads.mongodb.com/linux/mongodb-linux-x86_64-enterprise-debian92-4.0.16.tgz
RUN tar xf mongodb-linux-x86_64-enterprise-debian92-4.0.16.tgz
RUN mv mongo*/ /opt/mongodb/4.0

ENV PATH=/opt/mongodb/4.2/bin:$PATH

COPY Gemfile .
COPY *.gemspec .

RUN bundle install

COPY . .
