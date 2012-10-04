#!/usr/bin/env ruby

DEBUG = nil
require 'rubygems'
gem 'twitter'
require 'twitter'
require 'mechanize'
require 'hpricot'
require 'kconv'
require 'time'
require 'date'

# mixi user setting
username = 'mixi@mail.address'
password = 'mixipassword'

# Twitter: Key and Password
consumer_key = "consumer_key"
consumer_secret = "consumer_secret"
access_token_key = "consumer_token_key"
access_token_secret = "consumer_token_secret"

agent = Mechanize.new
agent.user_agent_alias = 'Mac Safari'

# Open mixi Page
page = agent.get('http://mixi.jp')
form = page.forms[0]

form.fields.find{|f| f.name == 'email'}.value = username
form.fields.find{|f| f.name == 'password'}.value = password
form.fields.find{|f| f.name == 'next_url'}.value = '/home.pl'
results = agent.submit(form)

url = "http://mixi.jp/view_bbs.pl?id=xxxxx&comm_id=yyyyyyyy&page=all"
bbs = agent.get(url)
htmldoc = Hpricot(bbs.body)

#Parse
maxnum = 0
$KCODE = "UTF-8"
ls = []
(htmldoc/"dl.commentContent01").each{|e|
  src = e.inner_html.toutf8.gsub(/<dd>/,"").gsub(/<\/dd>/,"").gsub(/<dt>.+?<\/dt>/m,"").gsub(/<br \/>/,"\n").gsub(/<!--.+?-->/m,'').gsub(/<a.+?\/a>/m,'').gsub(/<p.+?\/p>/,'').gsub(/<.+?>/m,'').gsub(/\r/,"").gsub(/\n+/,"\n")
  if !(src=~/\A\s*\Z/) then
    str = src
    while str.split(//u).length > 140 do
      str=~/\A(.{100,}?)\n/m
      str = $'
      ls << $1
      maxnum+=1
    end
    ls << str
    maxnum+=1
  end
}

sel = rand(maxnum)
#puts ls[sel]

# Twitter Setting
Twitter.configure do |config|
  config.consumer_key = consumer_key
  config.consumer_secret = consumer_secret
  config.oauth_token = access_token_key
  config.oauth_token_secret = access_token_secret
end

# Login
client = Twitter::Client.new
now = Time.now

begin
  #Post 
  client.update(ls[sel]) if maxnum > 0 unless DEBUG
  puts "#{now} : sel=#{sel}, maxnux=#{maxnum}, #{ls[sel]}"
rescue
  puts "#{now} : Post Error"
ensure
end

begin
  #Follow
  unfollowings = client.follower_ids.ids- client.friend_ids.ids  
  unfollowings.each{|uid|
    u = client.user(uid).screen_name
    client.friendship_create u unless DEBUG
  }
  puts "#{now} : Fowllowd #{unfollowings}" if unfollowings.length != 0
rescue
  puts "#{now} : Following Error"
ensure
end

begin
  #Unfollow
  oneway = client.friend_ids.ids - client.follower_ids.ids
  oneway.each{|uid|
    u = client.user(uid).screen_name
    client.friendship_destroy u unless DEBUG
  }
  puts "#{now} : Unfowllowd #{oneway}" if oneway.length != 0
rescue
  puts "#{now} : Unfollowing Error"
ensure
end

# Get Timeline
#puts client.home_timeline.first.text
