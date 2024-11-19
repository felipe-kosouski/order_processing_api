FROM ruby:3.3.5-slim

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    sqlite3 \
    build-essential \
    git \
    pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "/usr/local/bundle"/ruby/*/cache "/usr/local/bundle"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . /app

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]