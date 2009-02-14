#!/usr/bin/ruby

# Use Ruby 1.8

require "rubygems"
require "rack"
require "sinatra"

require 'yaml'

set :run => true
set :environment => :development
set :raise_errors => true
set :port => 3144

#log = File.new("sinatra.log", "a")
#STDOUT.reopen(log)
#STDERR.reopen(log)


use Rack::Auth::Basic do |username, password|
  username == 'stella' && password == 'stella'
end


get '/' do
  redirect '/product'
end

get '/product' do
  content_type "text/plain"
  product = {
    :id => (params[:id] || 0).to_i,
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
    :id => rand(100),
    :name => "John West Smoked Oysters",
    :convert => params[:convert] || false,
    :rand => params[:rand]
  }.to_yaml
end
