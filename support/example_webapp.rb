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
set :max_listings => 1000

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
  redirect '/' if blank?(params[:what]) && blank?(params[:where])
  params[:what] ||= ''
  params[:where] ||= ''
  @title << " - Search Results"
  @listings = filter_name(params[:what], options.listings)
  if !blank?(params[:where])
    @listings = filter_city(params[:where], @listings)
  end
  if @listings.empty?
    status 404
    erb :search_error 
  else
    erb :search_results
  end
end

get '/listing/add' do
  erb :add_form
end

post '/listing/add' do
  @title = "Add a Business"
  if blank?(params[:name]) || blank?(params[:city])
    status 500
    @msg = blank?(params[:city]) ? "Must specify city" : "Must specify name"
    erb :add_form
  else
    @listings = options.listings
    if filter_name(params[:name], @listings).empty?
      @listings.shift if @listings.size >= options.max_listings
      @listings << { :name => params[:name], :id => rand(10000), :city => params[:city] }
      redirect '/listings'
    else
      status 500
      @msg = "That business exists (#{params[:name]})"
      erb :add_form
    end
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
  { :id => 1000, :name => 'John West Smoked Oysters', :city => 'Toronto'  },
  { :id => 1001, :name => 'Fire Town Lightning Rods', :city => 'Toronto'  },
  { :id => 1002, :name => 'Oversized Pen and Ink Co', :city => 'Toronto'  },
  { :id => 1003, :name => 'The Rathzenburg Brothers', :city => 'Toronto'  },
  { :id => 1004, :name => 'Forever and Always Beads', :city => 'Montreal' },
  { :id => 1005, :name => "Big Al's Flavour Country", :city => 'Montreal' },
  { :id => 1006, :name => 'Big Time Furniture World', :city => 'Montreal' },
  { :id => 1007, :name => 'High-End Keyboard Makers', :city => 'Montreal' }
]


helpers do
  
  def blank?(v)
    v.nil? || v.empty?
  end
  
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
<p style="margin-left: 50px; margin-top: 20px;"><em>
<a href="/listing/add?name=<%= params[:what] %>&amp;city=<%= params[:where] %>">Add Listing</a> - 
<a href="/listings">View All</a> - 
<a href="/">New Search</a>
</em></p>
<%= yield %>
</body>
</html>

@@add_form
<% city = blank?(params[:city]) ? 'Toronto' : params[:city] %>
<% if !blank?(@msg) %>
<p style="color: red"><em>Error: <%= @msg %></em></p>
<% end %>
<form method="post">
Name: <input name="name" value="<%= params[:name] %>"/><br/>
City: <input name="city" value="<%= city %>" /><br/>
<input type="submit" />
</form>

@@listings
<% for listing in @listings %>
  <div class="listing" id="listing<%= listing[:id] %>"><a href="/listing/<%= listing[:id] %>.yaml"><%= listing[:name] %></a> <%= listing[:city] %></div>
<% end %>

@@search_form
<form action="/search">
What: <input name="what" /><br/>
Where: <input name="where" /><br/>
<input type="submit" />
</form>

@@search_results
Looking 
<% if !blank?(params[:what]) %>
for "<b><%= params[:what] %></b>"
<% end %>
<% if !blank?(params[:where]) %>
in "<b><%= params[:where] %></b>"
<% end %>
<% for listing in @listings %>
  <% name = listing[:name].gsub(/(#{params[:what]})/i, "<em><b>\\1</b></em>") %>
  <% city = listing[:city].gsub(/(#{params[:where]})/i, "<em><b>\\1</b></em>") %>
  <p><a href="/listing/<%= listing[:id] %>"><%= name %></a> <%= city %></p>
<% end %>

@@search_error
Looking for "<b><%= params[:what] %></b>" 
<% if !blank?(params[:where]) %>
in "<b><%= params[:where] %></b>"
<% end %>
<p><i>Nothing found</i></p>
