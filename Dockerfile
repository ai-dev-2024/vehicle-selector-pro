FROM ruby:3.2-slim

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential libpq-dev libyaml-dev git curl && \
    rm -rf /var/lib/apt/lists/*

# Install gems first to leverage Docker layer caching.
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'false' && bundle install

COPY . .

# Runtime directories excluded by .dockerignore but required at boot
# (Puma writes tmp/pids/server.pid; Rails expects log/ and storage/).
RUN mkdir -p tmp/pids log storage

# Dummy credentials so the Rails environment can boot for asset precompilation.
# Real values are injected at runtime via Fly secrets — never baked into the image.
ARG SECRET_KEY_BASE=dummy_secret_key_base_for_image_build_only_000
ARG SHOPIFY_API_KEY=dummy_api_key_for_build
ARG SHOPIFY_API_SECRET=dummy_api_secret_for_build
ARG DATABASE_URL=postgres://build:build@localhost/build_dummy
ENV RAILS_ENV=production \
    SECRET_KEY_BASE=${SECRET_KEY_BASE} \
    SHOPIFY_API_KEY=${SHOPIFY_API_KEY} \
    SHOPIFY_API_SECRET=${SHOPIFY_API_SECRET} \
    DATABASE_URL=${DATABASE_URL}

RUN bundle exec rails assets:precompile

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
