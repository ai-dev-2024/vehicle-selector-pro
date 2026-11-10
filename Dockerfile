FROM ruby:3.4.11-slim

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential libpq-dev libyaml-dev git curl && \
    rm -rf /var/lib/apt/lists/*

# Install gems first to leverage Docker layer caching.
COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'false' && bundle install

COPY . .

# Runtime directories excluded by .dockerignore but required at boot
# (Puma writes tmp/pids/server.pid; Rails expects log/ and storage/).
RUN mkdir -p tmp/pids log storage

# Dummy credentials so the Rails environment can boot for asset precompilation.
# They stay build ARGs on purpose: an ARG is visible to the RUN below but is
# not persisted into the image. Promoting them to ENV would let a deployment
# with a missing Fly secret boot on these public values instead of failing.
ARG SECRET_KEY_BASE=dummy_secret_key_base_for_image_build_only_000
ARG SHOPIFY_API_KEY=dummy_api_key_for_build
ARG SHOPIFY_API_SECRET=dummy_api_secret_for_build
ARG DATABASE_URL=postgres://build:build@localhost/build_dummy
ARG GIT_SHA=local
ENV RAILS_ENV=production \
    GIT_SHA=$GIT_SHA

RUN bundle exec rails assets:precompile

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
