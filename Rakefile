require 'rubygems'
require 'bundler/setup'
require 'dotenv'
require 'dotenv/tasks'
require './lib/twitterbot.rb'
require './config/twitterbot_config.rb'


begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
  # no rspec available
end

task :run do
  Dotenv.load
  Twitterbot.new(TWITTER_API_SETTINGS, TWITTERBOT_OPTIONS).gatsd
end
