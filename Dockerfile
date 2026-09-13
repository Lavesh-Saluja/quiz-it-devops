FROM ruby:3.3.10-slim AS base

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

WORKDIR /app

FROM base AS build

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      libpq-dev \
      libxml2-dev \
      libxslt1-dev \
      libyaml-dev \
      libffi-dev \
      autoconf \
      automake \
      pkg-config \
      curl \
      ca-certificates \
      nodejs \
      npm && \
    rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 2.6.5

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock ./
COPY .yarnrc.yml ./

RUN corepack enable && \
    corepack prepare yarn@4.6.0 --activate && \
    yarn install --immutable

COPY . .

RUN yarn build

RUN SECRET_KEY_BASE=build-only-not-a-secret \
    bundle exec rails assets:precompile

FROM base AS runtime

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      libxml2 \
      libxslt1.1 \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
