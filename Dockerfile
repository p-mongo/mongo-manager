FROM debian:9

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install -y git ruby ruby-bundler ruby-dev make gcc curl libsnmp30 procps

RUN mkdir /opt/mongodb

RUN curl -fL https://downloads.mongodb.com/linux/mongodb-linux-x86_64-enterprise-debian92-4.2.3.tgz \
  | tar xfz - && \
  mv mongo*/ /opt/mongodb/4.2

RUN curl -fL https://downloads.mongodb.com/linux/mongodb-linux-x86_64-enterprise-debian92-4.0.16.tgz \
  | tar xfz - && \
  mv mongo*/ /opt/mongodb/4.0

ENV PATH=/opt/mongodb/4.2/bin:$PATH

COPY Gemfile .
COPY *.gemspec .

RUN bundle install

COPY . .
