#!/usr/bin/env ruby
require 'rubygems'
require 'dotenv'
Dotenv.load
require './lib/twitterbot.rb'
require './config/twitterbot_config.rb'
t = Twitterbot.new(TWITTER_API_SETTINGS, TWITTERBOT_OPTIONS)
t.gatsd
