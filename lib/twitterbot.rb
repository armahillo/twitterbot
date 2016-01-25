#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'twitter'  # Twitter Gem
require './lib/string.rb' # Monkeypatches a truncate method into the String class 
require 'json' 
require 'fileutils'

## 
# Twitterbot just inherits directly from the Twitter REST Client, and extends
# it to incorporate some helper methods that help with retweet bot functions.
##
class Twitterbot < Twitter::REST::Client

  # Some of these methods may be unnecessary now.
  attr_reader :tweets
  attr_reader :search_tag
  attr_reader :block_file
  attr_reader :log
  attr_reader :profile_name

  def Twitterbot.valid_options?(options)
    [:consumer_key, :consumer_secret, :access_token, :access_token_secret, :profile_name, :search_tag].each do |key|
      return false if !options.has_key?(key) || options[key].nil? || options[key].empty?
    end
  end
  ##
  # See method #valid_options above for a list of required keys in the options hash.
  # This method should never make API calls, just prepare stuff. All API calls should begin in #gatsd
  ##
  def initialize(twitter_api_settings = {}, twitterbot_options = {})
    raise Exception.new("Invalid options, did you remember to set up your .env?: #{twitter_api_settings.inspect}, #{twitterbot_options.inspect}") unless Twitterbot.valid_options?(twitter_api_settings.merge(twitterbot_options))

    super(twitter_api_settings) # This Hash arg is set in twitterbot_config

    # Extended options:
    @verbose = twitterbot_options[:verbose] || false
    @search_tag = twitterbot_options[:search_tag]
    @profile_name = twitterbot_options[:profile_name]
    @block_file = twitterbot_options[:block_file] || "config/blocked_userids.json" 
    @last_log_file = twitterbot_options[:log_file] ||  "config/last_log.txt"
    @rate_limit_file = twitterbot_options[:rate_limit_file] || "config/pause_for_rate_limit"
    @last_tweet_sent_id = nil 
    # If the file doesn't exist, don't panic.
    @blocked = File.exists?(@block_file) ? (JSON.parse(File.read(@block_file))["blocked"] rescue []) : []
    @search_results = []   # raw search results
    @tweets = []           # Collect tweets into here
    @log = {}
  end

  

###
# Get All That Shit Done (^TM)
#-1. Check for rate limiting.
# 0. Update the blocked users list
# 1. Search for all tweets
# 2. Filter out bad tweets
# 3. Do the retweets
#  3a. Retweet public tweets
#  3b. Rebuild and Oldschool RT private tweets
# 4. Print summary if verbose
###
  def gatsd
    return false if rate_limited?
    @log["gatsd"] = []
    @last_tweet_sent_id = find_where_we_left_off # See method commentary
    begin
      update_blocked_list                       # (0) Updates the cache of blocked users
      @search_results = collect_tweets          # (1) Gathers tweets with #searchtag
      @tweets = process_tweets(@search_results) # (2) Run through them and check all tweets
      syndicate(@tweets)                        # (3) Retweet the tweets
    rescue Twitter::Error::TooManyRequests => error
      # Twitter's latest API uses pooled requests for ratelimiting. The script
      # should be cron'd to run on intervals, and it's clocked on a rolling basis, so as long 
      # as rate-limited requests are kept to a minimum, we should be good.
      # SEE: https://dev.twitter.com/rest/public/rate-limiting
      @log["gatsd"] << "Over rate limit, pausing for 10 mins. (#{error.rate_limit.reset_in/60}m #{error.rate_limit.reset_in%60}s)"
      FileUtils.touch(@rate_limit_file)
    rescue Exception => e
      @log["gatsd"] << "ERROR: #{e.inspect}"    # (4) Print an log report of what happened.
    ensure
      activity = log_activity(@log)
      puts activity if @verbose
    end
  end

public

  ##
  # Currently, the Twitter API Search only allows you to set your beginning point via
  #  a tweet instance. If they someday allow you to provide a DATETIME, that would be 
  #  preferable.
  # TODO: just go through the last 20 or 30 tweets in the search results and 
  # retweet all that have not been retweeted already, which would better deal with cases
  # where a tweet was manually retweeted by a human.
  ##
  def find_where_we_left_off
    t = user_timeline(@profile_name).first
    r = retweeted_by_me.first
    ((t.created_at > r.created_at) ? t.id : r.id)
  end

  ##
  # update_blocked_list
  #   To make administration easier, the blocked list for retweeting will directly
  #   mirror the block list of the account. This will be updated every time the 
  #   script runs. Checking blocked_ids does count against rate limiting.
  #   TODO: Add option for interval, in case rate-limiting is an issue. 
  ##
  def update_blocked_list()
    # Retrieves the current list of users blocked by the account
    block_list = self.blocked_ids.collect { |id| id.to_s }
    # manually generate the JSON string to export
    json_string = "{\"blocked\":#{block_list.inspect}}"
    # truncate the file and then re-dump it for next time.
    File.open(@block_file,'w') { |f| f.write(json_string) }
  end

  ##
  # collect_tweets
  #   Uses public search API to locate all tweets with the 
  #   search term
  ##
  def collect_tweets
    @log["collect"] = []
    search_results = nil
    begin
      search_results = search(@search_tag,
               :result_type => "recent",
               :since_id    => @last_tweet_sent_id,
               :rpp         => 100
              )
    # This happens sometimes.
    rescue Twitter::Error::ServiceUnavailable
      @log["collect"] << "Service unavailable"
      abort "(__X){ Unable to search Twitter."
    # This too.
    rescue Faraday::Error::ConnectionFailed
      @log["collect"] << "Faraday error"
      abort "Faraday connection problems."
    end
    return search_results
  end

  ## 
  # process_tweets
  #   Go through all pending tweets and omit the ones that are no good.
  ##
  def process_tweets(search_results)
    @log["process_tweets"] = []
    tweets = []
    search_results.each do |t| 
      begin
        # Runs against a batch of tests and raises an exception for the first one it violates
        check_tweet(t)
        # If it passes all tests, queue it up
        tweets << t
      rescue Exception => e
        @log["process_tweets"] << "Tweet #{t.id} failed because: #{e.inspect}"
      end
    end
    return tweets
  end

  
  ## 
  # syndicate
  #   This method is for when we know once and for all that a tweet should be syndicated
  #   Either do a retweet (nu-style) or build a manual retweet, and gracefully handle the
  #   failure.
  ##
  def syndicate(tweets)
    @log["syndicate"] = []
    tweets.each do |t|
      begin
        retweet(extract_id(t))
        @log["syndicate"] << "Retweeting: (#{t.id}) by #{t.user.screen_name}: #{t.uri}"

      rescue Twitter::Error::Unauthorized => e
      rescue Twitter::Error::Forbidden => e
      # The user likely has their status protected, so Twitter prevents RTs
      # Since we can't retweet officially, we'll do old-school instead
        retweet_text = prep_manual_retweet(t.user.screen_name, t.full_text)
        begin
          update(retweet_text)
          # For cron output. 
          @log["syndicate"] << "Manually Retweeting (#{t.id}) by #{t.user.screen_name} #{t.uri}"
        rescue Exception => e
          @log["syndicate"] << "ERROR while manually retweeting #{t.id} [#{e.inspect}]: #{retweet_text}"
        end
      end
    end
  end

  ##
  # log_activity
  #   Process the log and output it if necessary
  ##
  def log_activity(log)
    last_log = File.read(@last_log_file) rescue ""
    output = ""
    if last_log != log.inspect  
      File.open(@last_log_file, 'w') { |f| f.write(log.inspect) }
      log.each do |section, messages|
        next if messages.empty?
        output += "[#{section}]:\n"
        messages.each { |m| output += "\t - #{m}\n" }
      end
    end
    return output
  end

  ## 
  # check_tweet
  #   Run the tweet against a series of tests and raise an exception if it encounters one that invalidates
  #   it for retweeting.
  ## 
  def check_tweet(tweet)
    raise Exception.new("User @#{tweet.user.screen_name} (#{tweet.user.id}) is blocked") if blocking?(tweet.user.id)
    raise Exception.new("Tweet contains RT or MT") if oldschool_retweet?(tweet.text)
    raise Exception.new("Tweet is a retweet already") if (tweet.retweeted?)
    raise Exception.new("It's my own tweet") if by_me?(tweet.user.screen_name)
  end

  ##
  # prep_manual_retweet
  #   If the user has a protected timeline we can still retweet them. This prefixes the tweet with
  #   the old "RT @username " method, then truncates the tweet to 140 characters maximum. Truncation is
  #   handled somewhat naively.
  ##
  def prep_manual_retweet(screen_name, full_text)
    prefix = "RT #{screen_name} "
    # Strip out the search tag uses the monkeypatched truncate method.
    prefix + full_text.gsub(/\s+#{@search_tag}/,'').truncate(140-prefix.length, separator: ' ')
  end

  ##
  # rate_limited?
  #   if we're rate limited, we'll create a file that delays for 10 mins so we can catch up (return true)
  #   if 10 mins has elapsed then delete the file and proceed (return false)
  #   if 10 mins has not yet elapsed return true
  ##
  def rate_limited?
    return false unless File.exists?(@rate_limit_file)
    created = File.mtime(@rate_limit_file)
    elapsed_time_in_minutes = (Time.now - created)/60
    if (elapsed_time_in_minutes >= 10.0)
      File.unlink(@rate_limit_file)
      return false
    end
    return true
  end

protected
  ##
  # blocking?
  #   Polls manually blocked twitter IDs in @block_file
  ##
  def blocking?(id)
    @blocked.include?(id.to_s)
  end
  
  ## 
  # oldschool_retweet?
  #   is the tweet an old style retweet? We're ignoring those.
  ##
  def oldschool_retweet?(text)
    (text.include?('RT')) || (text.include?('MT'))
  end

  ##
  # by_me?
  #   Did this user do the tweet? We should not retweet those either.
  ##
  def by_me?(screen_name)
    screen_name == @profile_name
  end


=begin
  # Caching is for when we're rate limited. 
  # It doesn't appared to be used right now, though.
  def load_cache(file)
    if (!File.exists?(file))
      begin
        f = File.new(file, "w+")
      rescue IOError
        abort "Unable to create file #{file}"
      end
    else
      begin
        f = File.new(file, "r")
      rescue IOError
        abort "Unable to open file #{file}"
      end
    end

    begin
      line = f.gets
    rescue IOError
      abort "Unable to read data from #{file}"
    end

    contents = nil
    if (!line.nil?) then
      contents = JSON.parse(line)
    end

    f.close
    return contents
  end

  def save_cache(file, data)
    f = File.new(file, "w")
    f.write JSON.generate(data)
    f.close
  end
=end
  
public
=begin
  # not rate limited, as of API 1.1
  def follow_new_tweeps(list)
    @client.follow list
  end

  # not rate limited as of API 1.1
  def unfollow_old_tweeps(list)
    @client.unfollow(list)
  end

  # Stores a cache of followers. 
  def update_tweeps
    begin
      live_followers = @client.follower_ids.to_a
      live_following = @client.friend_ids.to_a
    rescue Twitter::Error::TooManyRequests => error
      puts "Over rate limit. Try again in #{error.rate_limit.reset_in}s"
      return false
    end

    cached_followers = load_cache(@followers) || Array.new
    cached_following = load_cache(@following) || Array.new

    new_follows = live_followers - cached_followers
    unfollows = cached_following - live_followers

#    unfollow_old_tweeps(unfollowed)
#    follow_new_tweeps(new_follows)
    puts "Unfollowed #{unfollows.count} users"
    puts "Followed #{new_follows.count} users"
    puts "Total change: #{new_follows.count - unfollows.count}"
    save_cache(@followers, live_followers)

  end
=end
end
