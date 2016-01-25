def stub_retweet
	allow_any_instance_of(Twitterbot).to receive(:retweet).and_return(true)
end

def stub_update
    allow_any_instance_of(Twitterbot).to receive(:update).and_return(true)
end

def stub_retweeted(return_val)
	allow_any_instance_of(Twitter::Tweet).to receive(:retweeted?).and_return(return_val)
end

def stub_oldschool_retweet(return_val)
	allow_any_instance_of(Twitterbot).to receive(:oldschool_retweet?).and_return(return_val)
end

def stub_by_me(return_val)
	allow_any_instance_of(Twitterbot).to receive(:by_me?).and_return(return_val)
end

def stub_find_where_we_left_off(return_val)
	allow_any_instance_of(Twitterbot).to receive(:find_where_we_left_off).and_return(return_val)
end

def stub_blocked_ids(return_val = [])
	allow_any_instance_of(Twitterbot).to receive(:blocked_ids).and_return(return_val)
end

def stub_syndicate(return_val = nil)
	allow_any_instance_of(Twitterbot).to receive(:syndicate).and_return(return_val)
end

def stub_rate_limited(return_val)
    allow_any_instance_of(Twitterbot).to receive(:rate_limited?).and_return(return_val)
end