FROM ruby:3.2-slim
WORKDIR /app
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs npm && rm -rf /var/lib/apt/lists/*
COPY Gemfile* ./
RUN bundle install
COPY . .
RUN bundle exec rails assets:precompile 2>/dev/null || true
EXPOSE 3000
CMD ["bundle","exec","puma","-C","config/puma.rb"]
