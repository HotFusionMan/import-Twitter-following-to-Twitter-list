=begin
# As of this writing, the following installs twitter 0.8.3, which gem will install oauth and hashie as prerequisites.
sudo gem install twitter
=end

require 'config_store'
# TODO:  Actually use OAuth and stop having to copy Nunemaker's ConfigStore around to my Twitter projects.
require 'twitter'


twitter_config = ConfigStore.new( "#{ENV['HOME']}/.twitter" )

twitter_username = twitter_config['username']
twitter_password = twitter_config['password']


httpauth = Twitter::HTTPAuth.new( twitter_username, twitter_password, :ssl => TRUE )
base = Twitter::Base.new( httpauth )


list_name = 'my-following' # "following" is not an allowed name for a Twitter list.
# Underscores in Twitter list names are silently replaced with hyphens at list creation time!

list_options = { :name => list_name }
#list_options[:mode] =  if # public/private mode was specified
#list_options[:description] =  if # a description of the list was provided
list = base.list_create( twitter_username, list_options ) #unless list exists already, in which case skip creation and add only the users who aren't already in the list


friend_ids = base.friend_ids
# TODO:  Comply with Twitter's new cursoring strategy:
# number_of_friend_id_pages =
number_of_friends = friend_ids.length
friend_ids.reverse.each_with_index { |i, id|
  puts "Adding #{i} of #{number_of_friends}"

  begin
    base.list_add_member( twitter_username, list_name, id )
  rescue Twitter::NotFound => e
    puts e.message
    sleep 5
    retry
  rescue Twitter::Unavailable => e
    sleep 5
    retry
  rescue Twitter::RateLimitExceeded => e
    twitter_API_rate_reset_time_in_seconds = base.rate_limit_status.reset_time_in_seconds
    minutes_until_rate_limit_is_reset = ( twitter_API_rate_reset_time_in_seconds - Time.now.to_i ) / 60.0
    puts "Sorry, we've exceeded the Twitter-imposed rate limit for accessing their service.  We'll have to wait #{minutes_until_rate_limit_is_reset} minutes before this account can access Twitter again."
    sleep twitter_API_rate_reset_time_in_seconds
    retry
  end
}
