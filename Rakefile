# encoding: utf-8
# frozen_string_literal: true

begin
  require 'bundler/setup'
end

require 'rubygems/tasks'
Gem::Tasks.new

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    abort 'Rubocop is not available.'
  end
end
