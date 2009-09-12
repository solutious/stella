#!/usr/bin/ruby

# Use Ruby 1.8

require "rubygems"
require "rack"
require "sinatra"

require 'yaml'

set :run => true
set :environment => :development
set :dump_errors => true
set :port => 3114
set :reload => true

#log = File.new("/dev/null", "a")
#STDOUT.reopen(log)
#STDERR.reopen(log)

#use Rack::Auth::Basic do |username, password|
#  username == 'stella' && password == 'stella'
#end

before do
  @title = "Business Finder"
end

get '/' do
  @title << " - Search"
  erb :search_form
end


get '/search' do
  redirect '/' if params[:what].nil? || params[:what].empty?
  @title << " - Search Results"
  @listings = filter_name(params[:what], options.listings)
  if params[:where].nil? || params[:where].empty? 
    @listings = filter_city(params[:where], @listings)
  end
  erb @listings.empty? ? :nothing : :search
end

get '/listing/add' do
  @title = "Add a Business"
  if params[:name] && params[:city]
    @listings = options.listings
    @listings << { :name => params[:name], :id => rand(10000), :city => params[:city] }
    redirect '/listings'
  else
    erb :add_form
  end
end

get '/listing/:id.yaml' do 
  content_type "text/plain"
  listing = filter_id params[:id], options.listings
  listing.to_yaml
end

get '/listing/:id' do 
  @listings = filter_id(params[:id], options.listings)
  redirect '/' if @listings.empty?
  @title = "Business Listing - #{@listings.first[:name]}"
  erb :listings
end

get '/listings' do
  @listings = options.listings
  @title = "Business Listings"
  erb :listings
end


set :listings => [
  { :id => 1000, :name => 'John West Smoked Oysters', :city => 'Toronto' },
  { :id => 1001, :name => 'Fire Town Lightning Rods', :city => 'Toronto' },
  { :id => 1002, :name => 'Oversized Pen and Ink Co', :city => 'Toronto' },
  { :id => 1003, :name => 'The Rathzenburg Brothers', :city => 'Toronto' },
  { :id => 1004, :name => 'Forever and Always Beads', :city => 'Montreal' },
  { :id => 1005, :name => "Big Al's Flavour Country", :city => 'Montreal' },
  { :id => 1006, :name => 'Big Time Furniture World', :city => 'Montreal' },
  { :id => 1007, :name => 'High-End Keyboard Makers', :city => 'Montreal' }
]


helpers do
  
  def filter_id(id, listings)
    listings.select { |l| l[:id] == id.to_i }
  end
  
  def filter_name(name, listings)
    listings.select { |l| l[:name].match(/#{name}/i) }
  end
  
  def filter_city(city, listings)
    listings.select { |l| l[:city].match(/#{city}/i) }
  end
  
  # Generates a string of random alphanumeric characters
  # These are used as IDs throughout the system
  def strand( len )
     chars = ("a".."z").to_a + ("0".."9").to_a
     newpass = ""
     1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
     return newpass
  end
  
end

__END__

@@layout
<html>
<head>
<title><%= @title %></title>
</head>
<body>
<h1>Business Finder</h1>
<%= yield %>
<p style="margin-left: 50px; margin-top: 20px">
<a  href="/listing/add">Add Listing</a> - 
<a href="/listings">View All</a> - 
<a href="/">New Search</a>
</p>
</body>
</html>

@@search_form
<form action="/search">
What: <input name="what" /><br/>
Where: <input name="where" /><br/>
<input type="submit" />
</form>

@@add_form
<form>
Name: <input name="name" /><br/>
City: <input name="city" value="Toronto" /><br/>
<input type="submit" />
</form>

@@search
Looking for "<b><%= params[:what] %></b>" in "<b><%= params[:where] %></b>"
<% for listing in @listings %>
  <% name = listing[:name].gsub(/(#{params[:what]})/i, "<em><b>\\1</b></em>") %>
  <% city = listing[:city].gsub(/(#{params[:where]})/i, "<em><b>\\1</b></em>") %>
  <p><a href="/listing/<%= listing[:id] %>"><%= name %></a> <%= city %></p>
<% end %>

@@listings
<% for listing in @listings %>
  <p><a href="/listing/<%= listing[:id] %>.yaml"><%= listing[:name] %></a> <%= listing[:city] %></p>
<% end %>

@@nothing
Looking for "<b><%= params[:what] %></b>" 
<% if !params[:where].empty? %>
in "<b><%= params[:where] %></b>"
<% end %>
<p><i>Nothing found</i> (<a href="/listings">view all</a>)</p>


