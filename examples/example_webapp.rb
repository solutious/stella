#!/usr/bin/ruby

# Use Ruby 1.8

require "rubygems"
require "rack"
require "sinatra"

require 'yaml'

set :run => true
set :environment => :development
set :raise_errors => true
set :port => 3114

#log = File.new("/dev/null", "a")
#STDOUT.reopen(log)
#STDERR.reopen(log)


#use Rack::Auth::Basic do |username, password|
#  username == 'stella' && password == 'stella'
#end

# 
# Generates a string of random alphanumeric characters
# These are used as IDs throughout the system
def strand( len )
   chars = ("a".."z").to_a + ("0".."9").to_a
   newpass = ""
   1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
   return newpass
end

get '/' do
  redirect '/product'
end

get '/product' do
  content_type "text/plain"
  product = {
    :id => (params[:id] || 0).to_s,
    :name => "John West Smoked Oysters"
  }.to_yaml
end

get '/product/:id' do 
  content_type "text/plain"
  product = {
    :id => params[:id].to_i,
    :name => "John West Smoked Oysters"
  }.to_yaml
end

post '/upload' do
  content_type "text/plain"
  product = {
    :id => strand(3),
    :name => "John West Smoked Oysters",
    :convert => params[:convert] || false,
    :rand => params[:rand]
  }.to_yaml
end
