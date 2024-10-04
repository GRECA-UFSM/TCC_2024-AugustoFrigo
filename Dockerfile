FROM ruby:3.3.4-alpine
RUN mkdir 'authority' && \
    apk upgrade && apk add openssl-dev build-base && \
    gem install sinatra openssl redis securerandom pry-nav base64 \
    json digest yaml puma rackup && \
    apk del openssl-dev build-base
WORKDIR 'authority'
COPY . '/authority'