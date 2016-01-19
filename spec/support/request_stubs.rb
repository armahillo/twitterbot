def stub_retweet
	allow_any_instance_of(Twitterbot).to receive(:retweet).and_return(true)
end

def stub_update
    allow_any_instance_of(Twitterbot).to receive(:update).and_return(true)
end

def stub_retweeted(return_val)
	allow_any_instance_of(Twitterbot).to receive(:retweeted?).and_return(return_val)
end

def stub_find_where_we_left_off(return_val)
	allow_any_instance_of(Twitterbot).to receive(:find_where_we_left_off).and_return(return_val)
end