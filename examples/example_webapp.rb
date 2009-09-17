#!/usr/bin/ruby

# Use Ruby 1.8

require "rubygems"
require "rack"
require "sinatra"

require 'yaml'

set :run => $0 == __FILE__ ? true : false
set :environment => :development
set :dump_errors => true
set :port => 3114
set :reload => true
set :max_listings => 1000

LISTINGS = [
  { :id => 1000, :name => 'John West Smoked Oysters', :city => 'Toronto'  },
  { :id => 1001, :name => 'Fire Town Lightning Rods', :city => 'Toronto'  },
  { :id => 1002, :name => 'Oversized Pen and Ink Co', :city => 'Toronto'  },
  { :id => 1003, :name => 'The Rathzenburg Brothers', :city => 'Toronto'  },
  { :id => 1004, :name => 'Forever and Always Beads', :city => 'Montreal' },
  { :id => 1005, :name => "Big Al's Flavour Country", :city => 'Montreal' },
  { :id => 1006, :name => 'Big Time Furniture World', :city => 'Montreal' },
  { :id => 1007, :name => 'High-End Keyboard Makers', :city => 'Montreal' }
]

set :listings => LISTINGS.clone

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


get '/search/?' do
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
    if find_name(params[:name], @listings).empty?
      @listings.shift if @listings.size >= options.max_listings
      @listings << { :name => params[:name], :id => rand(100000), :city => params[:city] }
      redirect '/listings'
    else
      status 500
      @msg = "That business exists (#{params[:name]})"
      erb :add_form
    end
  end
end

get '/listing/:id.yaml' do 
  content_type "text/yaml"
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

get '/listings.yaml' do
  content_type "text/yaml"
  @listings = options.listings
  @title = "Business Listings"
  @listings.to_yaml
end


before do
  @cookie = request.cookies["bff-history"]
  @cookie = blank?(@cookie) ? {} : YAML.load(@cookie)
  @cookie[:history] ||= []
  if params[:clear] == 'true'
    @cookie[:history] = []
    @cookie[:location] = ''
    set :listings => LISTINGS.clone
  end
  @cookie[:history].delete params[:what]
  @cookie[:history].unshift params[:what] unless blank?(params[:what])
  @cookie[:history].pop if @cookie[:history].size > 5
  @cookie[:location] = params[:where] unless blank?(params[:where])
  response.set_cookie "bff-history", :path => '/', :value => @cookie.to_yaml
end

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
  
  def find_name(name, listings)
    listings.select { |l| l[:name] == name }
  end
  
  def filter_city(city, listings)
    listings.select { |l| l[:city].match(/#{city}/i) }
  end
  
  def format_listing(lid, name, city)
    listing = %Q{<div class="listing" id="listing-#{lid}">}
    listing << %Q{<a href="/listing/#{lid}.yaml">#{name}</a> }
    listing << %Q{#{city}</div>}
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
<style>
.hilite { background-color: #FEE00B; font-weight: bold; }
.footer { color: #ccc; font-weight: lighter; font-size: 80%; margin-top: 30px; }
.footer a { color: #69c;}
</style>
</head>
<body>
<h1>Business Finder</h1>
<p style="margin-left: 50px; margin-top: 20px;"><em>
<a href="/">New Search</a> -
<a href="/listing/add?name=<%= params[:what] %>&amp;city=<%= params[:where] %>">Add Listing</a> - 
<a href="/?clear=true">!!</a> -
<a href="/listings">View All</a>
</em></p>
<%= yield %>
<div class="footer">
A <a href="http://solutious.com/projects/stella/">Stella</a> demo by <a href="http://solutious.com/">Solutious</a>. 
</div>
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
<% for l in @listings %>
  <%= format_listing(l[:id], l[:name], l[:city]) %>
<% end %>

@@search_form
<form action="/search">
What: <input name="what" value="" /><br/>
Where: <input name="where" value="<%= @cookie[:location] %>" /><br/>
<input type="submit" />
</form>
<ul id="history">
  <% unless @cookie[:history].empty? %>
  <h3>Previous Searches</h3>
  <% end %>
  <% for what in @cookie[:history] %>
  <li><em><a href="/search/?what=<%= what %>&amp;where=<%= @cookie[:location] %>"><%= what %></a></em></li>
  <% end %>
</ul>

@@search_results
Looking 
<% if !blank?(params[:what]) %>
for "<b><%= params[:what] %></b>"
<% end %>
<% if !blank?(params[:where]) %>
in "<b><%= params[:where] %></b>"
<% end %>
<br/><br/> 
<% for l in @listings %>
  <% name = l[:name].gsub(/(#{params[:what]})/i, "<span class='hilite'>\\1</span>") %>
  <% city = l[:city].gsub(/(#{params[:where]})/i, "<span class='hilite'>\\1</span>") %>
  <%= format_listing(l[:id], name, city) %>
<% end %>

@@search_error
Looking for "<b><%= params[:what] %></b>" 
<% if !blank?(params[:where]) %>
in "<b><%= params[:where] %></b>"
<% end %>
<p><i>Nothing found</i></p>
