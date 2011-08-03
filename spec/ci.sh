#!/usr/bin/env sh
cp spec/database.yml.example spec/database.yml && bundle install && bundle exec rake prepare_ci_env db:create db:migrate && bundle exec rake spec
