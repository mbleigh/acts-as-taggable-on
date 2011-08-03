#!/usr/bin/env sh
cp spec/database.yml.example spec/database.yml && bundle install && bundle exec rake
