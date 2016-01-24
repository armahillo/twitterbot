require 'spec_helper'
require './lib/twitterbot.rb'

RSpec.describe Twitterbot do

  let!(:twitter_api_config) { { 
      :consumer_key => "fake",
      :consumer_secret => "fake",
      :access_token => "fake",
      :access_token_secret => "fake"
      } }
  let!(:twitterbot_config) { { 
      :profile_name => "twithaca",
      :search_tag => "#twithaca",
      :block_file => "spec/support/blocked_userids.json",
      :log_file => "spec/support/last_log.txt"
     } }
  let(:twitterbot) { Twitterbot.new(twitter_api_config, twitterbot_config) }

  
  it "creates an instance" do
    expect(twitterbot).not_to be_nil
  end

  describe "Cassettes" do
    it "has a cassette for find_where_we_left_off" do
      VCR.use_cassette("find_where_we_left_off") do
        result = twitterbot.find_where_we_left_off
        expect(result).not_to be_nil
      end
    end

    it "has a cassette for collect_tweets" do
      VCR.use_cassette("collect_tweets") do
        #allow(twitterbot).to receive(:find_where_we_left_off) { 689212732642443264 }
        stub_find_where_we_left_off(689212732642443264)
        result = twitterbot.collect_tweets
        expect(result.first.text).not_to be_nil
      end
    end
  end

  describe "Blockfile" do
    before(:each) do
      @alternate_config = { :profile_name => "twithaca", :search_tag => "#twithaca", :block_file => "spec/support/nonexistent.txt" }
      # We need to use an alternate configuration here, so that we can delete the blockfile
      @alt_twitterbot = Twitterbot.new(twitter_api_config, @alternate_config)
    end

    after(:each) do
      # Clean up!
      File.unlink(@alternate_config[:block_file])
    end

    it "doesn't panic if the blockfile doesn't exist" do
      
      # Verify that it isn't lingering from a previous test
      expect(@alt_twitterbot.block_file).to eq(@alternate_config[:block_file])
      expect(File.exists?(@alternate_config[:block_file])).to eq(false)
      # Stub the blocked_ids request because it's irrelevant
      stub_blocked_ids
      # Run the method that should create the block file as a side effect
      @alt_twitterbot.update_blocked_list
      expect(File.exists?(@alternate_config[:block_file])).to eq(true)
    end

    pending "allows a user's tweet if their user ID is not in the block file" do
# Having some VCR issues with these
      # We want to control who is in the resultset
      stub_blocked_ids()
      # this will be checked and we don't care
      stub_retweeted(false)
      stub_oldschool_retweet(false)
      stub_by_me(false)

      result = nil
      @alt_twitterbot.update_blocked_list
      VCR.use_cassette("collect_tweets") do
        # One of the tweets that's been recorded
        stub_find_where_we_left_off(689212732642443264)
        result = @alt_twitterbot.collect_tweets
      end
      #VCR.use_cassette("search_results") do
      #  ok_tweets = @alt_twitterbot.process_tweets(result)
      #end
      
      puts ok_tweets.inspect
      puts @alt_twitterbot.log.inspect
      
      expect(ok_tweets).not_to be_empty
      #expect(@alt_twitterbot.check_tweet(result.first)).to raise_exception
    end

    pending "skips a user's tweet if their userID is in the block file" do
      # We want to control who is in the resultset
      stub_blocked_ids([110536502])
      # this will be checked and we don't care
      stub_retweeted(false)
      stub_oldschool_retweet(false)
      stub_by_me(false)

      result = nil
      #@alt_twitterbot.update_blocked_list
      VCR.use_cassette("collect_tweets") do
        # One of the tweets that's been recorded
        stub_find_where_we_left_off(689212732642443264)
        #result = @alt_twitterbot.collect_tweets
        @alt_twitterbot.gatsd
      end
      
      ok_tweets = @alt_twitterbot.process_tweets
      puts @alt_twitterbot.log.inspect
      #expect(@alt_twitterbot.check_tweet(result.first)).to raise_exception
    end
  end

  describe "Logging" do
    it "updates the log file if it's different" do
      # Reset the file so it forces a rewrite
      File.open(twitterbot_config[:log_file], 'w') { |f| f.write("{}") }
      fake_log = {}
      fake_log["foo"] = ["bar", "baz"]
      # Since the file is different, it will update the file and output the result
      output = twitterbot.log_activity(fake_log)
      expect(output).not_to eq("")
      # This time, though, the output is the same so it won't re-run it.
      second_output = twitterbot.log_activity(fake_log)
      expect(second_output).to eq("")
    end

  end

  describe "Methods" do
    describe "find_where_we_left_off" do
      it "returns an ID" do
        VCR.use_cassette("find_where_we_left_off") do
          result = twitterbot.find_where_we_left_off
          expect(result).to be_is_a(Fixnum)
        end
      end
    end
    
    
    describe "Retweet" do
      context "with an open timeline" do
        it "retweets" do
        end

        context "if the user is blocked" do
          it "skips the tweet" do
          end
        end
        context "if the tweet is a retweet itself" do
          it "skips the tweet" do
          end
        end
        context "if the tweet is by the twitterbot user" do
          it "skips the tweet" do
          end
        end

      end
      context "with a protected timeline" do
        it "reformats the tweet to manually RT it" do
        end
      end
    end
  end

  context "When it receives @mentions" do
    it "replies to the user directly, if they have not been seen already" do
    end
    it "stores a record that is has responded to them" do
    end
    it "skips the user if it has already responded to them" do
    end
  end

  context "when it sees #search_tag" do
    it "retweets the tweet if it's by a normal user" do
    end
    it "ignores if the user is on the ban list" do
    end
    it "retweets the tweet if it's by a throttled user but they're under their limit" do
    end
    it "ignores the tweet if it's by a throttled user and they're over their limit" do
    end
    it "manually retweets if they're a protected feed" do
    end
  end

end
