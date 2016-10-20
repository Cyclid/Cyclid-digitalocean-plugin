# frozen_string_literal: true
require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

# Configure RSpec
RSpec::Expectations.configuration.warn_about_potential_false_positives = false

# Mock external HTTP requests
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)
WebMock::Config.instance.query_values_notation = :flat_array

# Use the development/test configuration file
ENV['CYCLID_CONFIG'] = File.join(%w(config development))

# Pull in Cyclid and the plugin
require 'cyclid/app'
require_relative '../lib/cyclid/plugins/builder/digitalocean'
