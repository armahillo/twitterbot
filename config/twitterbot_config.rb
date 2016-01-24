#!/usr/bin/env ruby

# API info for Twitter
TWITTER_API_SETTINGS = {
  :consumer_key => ENV["CONSUMER_KEY"],
  :consumer_secret => ENV["CONSUMER_SECRET"],
  :access_token => ENV["ACCESS_TOKEN"],
  :access_token_secret => ENV["ACCESS_TOKEN_SECRET"]
}

TWITTERBOT_OPTIONS = {
  :profile_name => ENV["PROFILE_NAME"],
  :search_tag => ENV["SEARCH_TAG"],
  :block_file => ENV["BLOCK_FILE_PATH"]
  :verbose => ENV["VERBOSE"] || false
}
