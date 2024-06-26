# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gemspec

gem 'pg'

gem 'aws-sdk-s3', '=1.143.0'
gem 'fog-local'

gem 'delayed_paperclip', github: 'insales/delayed_paperclip'
gem 'rails'
gem 'sidekiq', '~>6.5' # in 6.4.2 worker started to be renamed to job, in 7 removed

gem 'test-unit'
gem 'simplecov', require: false
gem 'mocha'
gem 'thoughtbot-shoulda', '>= 2.9.0'

gem 'pry'
gem 'pry-byebug'

unless defined?(Appraisal)
  gem 'appraisal'

  group :lint do
    gem 'rubocop'
    gem 'rubocop-rails'
    gem 'rubocop-rspec'
    gem 'rubocop-performance'

    gem 'pronto', '>= 0.11', require: false
    gem 'pronto-brakeman', require: false
    gem 'pronto-rubocop', require: false
  end
end
