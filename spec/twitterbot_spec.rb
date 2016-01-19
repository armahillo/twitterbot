require 'spec_helper'
require './lib/twitterbot.rb'

RSpec.describe Twitterbot do

  let!(:twitterbot) { Twitterbot.new(
     {
      :consumer_key => "fake",
      :consumer_secret => "fake",
      :access_token => "fake",
      :access_token_secret => "fake"
     }, {
      :profile_name => "twithaca",
      :search_tag => "#twithaca",
      :block_file => "spec/support/blocked_userids.json"
     }
    ) }

  
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
        expect(result).not_to be_nil
      end
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
