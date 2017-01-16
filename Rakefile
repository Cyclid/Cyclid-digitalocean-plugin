# encoding: utf-8
# frozen_string_literal: true

begin
  require 'bundler/setup'
end

ENV['CYCLID_CONFIG'] = File.join(%w(config development))

require 'rubygems/tasks'
Gem::Tasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    abort 'Rubocop is not available.'
  end
end

task :rackup do
  system 'rackup ' + File.expand_path("../../Cyclid/config.ru", __FILE__)
end

task :redis do
  require 'redis'
  exec 'redis-server'
end

task :sidekiq do
  exec 'sidekiq -r ' + File.expand_path("../../Cyclid/lib/cyclid/app.rb", __FILE__)
end
