FROM ruby:2.6.3

ARG RAILS_MASTER_KEY

ENV APP_ROOT /usr/src/showks-form

WORKDIR $APP_ROOT

COPY Gemfile Gemfile.lock $APP_ROOT/
RUN apt-get update && \
    apt-get install -y cmake jq sqlite3 mariadb-client && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash && \
    apt-get install -y nodejs && \
    npm install -g yarnpkg && \
    bundle install
COPY . $APP_ROOT/

RUN rake assets:precompile RAILS_ENV=production

EXPOSE 3000
CMD ["rails", "s", "-b", "0.0.0.0"]

