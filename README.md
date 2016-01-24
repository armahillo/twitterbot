# twitterbot
Twitter Retweeting Bot, written in Ruby

# Summary
Twitterbot is a very simple retweeting bot that triggers off of the usage of a hashtag. It has basic administrative features for pre-empting spam. 

In the real world, it is used like this:

You set up your Twitterbot instance to trigger on #foobar, and configure it to run every couple minutes (via a cronjob)

Someone tweets "Hey I found some awesome #foobar at your mom's house!"

When the cronjob fires, it will see that tweet, retweet it to the best of its ability. There is no database and any caching is handled with small JSON files on the filesystem (for example, IDs that are blocked)

# Usage

Running Twitterbot (once configured) is as simple as:

  rake run

If verbose is set to true in the configuration file, it will print out any relevant messages (errors or actions taken). If there is nothing to do, it will remain silent.

# Dependencies

## Ruby
Twitterbot has been tested and configured for Ruby v1.9.3, and the Ruby version is specified in the Gemfile. If you use a Ruby versioning manager such as RVM, you may be required to install the binaries for that version (rvm install ruby-1.9.3 should do it). It is likely compatible with newer version of Ruby but I have not tested for regression errors.

## Gems Used

 * Rake
 * Twitter ~> 5.11 (http://github.com/sferik/twitter)
 * JSON / MultiJSON
 * DotEnv

Twitterbot extends Sferik's awesome Twitter API wrapping gem, adding additional features specifically for functioning as a retweet bot. As of this commit, it is using version 5.11.0. Because of how tightly coupled this script is to that source gem, version has been locked down. Should Sferik need to update his gem to accommodate API changes in Twitter (it happens :c #lesigh), this gem will need to be tested with that new version for regressions.

These gems are used in the test site (See below). 
 * RSpec
 * VCR
 * Webmock

## Test Suite
There are some very basic tests, and the VCR gem has been used to capture API output. Additional test coverage should be added eventually.

# Configuration
Twitterbot has been tested in development and production environments on the Ubuntu operating system, versions 14.04 and 15.10. Any OS capable of running the above gems *should* be able to run Twitterbot, in theory, though.

## Twitter API
Before you set up the script on your server, you will need an API key. Create the Twitter account that will be the bot (ie. "@mytwitterbot"), log in as that user, and then register your app with Twitter: 

https://apps.twitter.com/ 

jot down your:

 * CONSUMER_KEY (allows the app to access the Twitter API)
 * CONSUMER_SECRET
 * ACCESS_TOKEN  (allows the app to post to your timeline and retweet)
 * ACCESS_TOKEN_SECRET 

## Twitterbot deployment config
You will need to create a .env file in your application root. Put it at the same level as the Gemfile in this app. The app *will not work* without this .env file configured correctly, and it will specifically complain about that.

Your .env file can be templated like this:

  CONSUMER_KEY=fromtwitterapi
  CONSUMER_SECRET=fromtwitterapi
  ACCESS_TOKEN=fromtwitterapi
  ACCESS_TOKEN_SECRET=fromtwitterapi
  PROFILE_NAME=mytwitterbot
  SEARCH_TAG="#foobar"
  BLOCK_FILE_PATH=config/blocked_userids.json
  VERBOSE=true

Be sure to change all but the last two options. The final option is up to you -- keeping it verbose will dump messages to STDOUT if it performs any work or encounters any problem during execution. The blockfile need only be created (*touch config/blocked_userids.json*  will work); the script will handle the read/write to the file. 

## Setting up with Cron

Server configuration varies, but the only command that need be run is the one listed above: "rake run". Your system may require it be run through bundle "bundle exec rake run", or you may have to indicate something more specific if you use a versioning manager.

Twitter does ratelimit and will throttle you if you use the API too much in a given time period, however I have used this in a production situation with the script running every 2 minutes and have not been throttled. Running it on the minute might be possible.

If you are only concerned of status messages if it is breaking, then set "Verbose" to "false". If you would like to know when it does all the things, set "Verbose" to "true" -- no e-mail will be sent if it finds nothing to do. 

# Contributing

## As a user

If you use this (either as an administrator or a twitter user) and have feature suggestions / requests, or have identified bugs or issues, please file them with this repository.

## As a developer

If you would like to contibute to this, please submit a Pull Request with your changes.

 1. Fork this repository
 2. Clone your forked-repo to your workspace
 3. Make your changes, push your changes up to your forked-repo
 4. Submit a Pull Request to this repository matching it to your branch with your latest commit.

If you add additional features or fix a bug, please add a test to the test suite that covers this change. 