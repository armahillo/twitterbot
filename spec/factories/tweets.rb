require 'ostruct'

class Tweet < OpenStruct
	def to_s
		self.marshal_dump
	end
end

FactoryGirl.define do
	to_create { |instance| instance.persist! }

 	factory :tweet do
 		created_at { Time.now }
 		sequence(:id) { |n| 100000000 + n }
 		text "A tweet"
 		source "<a href=\"http://www.twitter.com/justinbieber\" rel=\"nofollow\">JustinBieber</a>"
 		truncated false
 	end
 end