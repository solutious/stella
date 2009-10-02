# Stella - Example Test Plan
# 
#
# 1. INTRODUCTION
#
# A test plan is a group of one or more user 
# scenarios. This allows you to simulate the
# kind of traffic your application is exposed
# to in the wild. Realistic tests are really
# important because they give you a much more
# accurate view of how your application is
# performing. 
#
# A scenario (or "usecase") is a group a 
# requests that represents a typical path
# that a real person would take through 
# your site. 
#
# This plan contains 3 scenarios:
# 
# - Simple Search (60%)
# - YAML API (30%)
# - Self-serve API (10%)
#
# The percentages represent the relative amount 
# of traffic to be generated for each scenario.
# In a test with 100 virtual users, 60 would 
# follow the Simple Search usecase, 30 the YAML
# API, and 10 would following the Self-Serve API.
#
#
# 2. THE CONFIGURATION LANGUAGE
# 
# Test plans are defined in a streamlined version
# of the Ruby programming language. Using a "real"
# languages gives you a lot of power to specify 
# complex operations. 
#
#
# 3. START THE EXAMPLE APPLICATION
# 
# You need to start the example web application before
# running this testplan. You can do this in one of the
# following ways:
# 
# $ ruby examples/example_webapp.rb
#
#     OR
#
# $ thin -R examples/example_webapp.ru start
#
# You can check that it's running by going to:
# http://127.0.0.1:3000/
#
#
# 4. RUNNING THE TEST PLAN
#
# You run this test plan from the command line.
# First you verify that the plan and application
# are running correctly:
#
# $ stella verify -p examples/essentials/plan.rb http://127.0.0.1:3000/
# 
# The "verify" command executes the plan with a 
# single user and provides more detailed output.
#
# "load" tests are run in a similar way:
# 
# $ stella load -c 50 -r 10 -p examples/essentials/plan.rb http://127.0.0.1:3000/
#
# where "c" is the number of concurrent users and
# "r" is the number of times to repeat the plan. 
#
# 
# 5. WRITING A TEST PLAN
#
# The following is an example of a working test plan. 
# I put a lot of effort into keeping the syntax simple
# but feel free to contact me if you have any questions
# or problems.
#
# Happy Testing!
#
# Delano (@solutious.com) 
#

desc "Business Finder Testplan"

usecase 65, "Simple search" do
  
  # An important factor in simulating traffic
  # is using real, dynamic data. You can load
  # data from a file using the resource method.
  # Here is an example which reads a list of 
  # search terms ("restaurant", "hotel", ...)
  # into an array called :search_terms. The 
  # colon is Ruby's way of defining a symbol.
  #
  resource :search_terms, list('search_terms.csv')
  
  # Requests are defined with one of the 
  # following methods: get, post, head, delete.
  # Here we define a simple get request for the
  # homepage ("/").
  #
  get "/", "Homepage" do
    # This tells Stella to wait between 1 and 5
    # seconds before moving to the next request.
    wait 1..5
  end
  
  # In this request, the user has entered a simple
  # what and where search. You'll notice that we
  # aren't specifying a hostname or port number for
  # these requests. We do that so you use the same
  # test plan to run tests on machines with different
  # hostnames. However, this is optional. You can
  # also specify absolute URIs like this:
  #
  #     get "http://example.com:8000/search"
  #
  get "/search", "Search Results" do
    wait 2..5
    
    # Two URI parameters will be included with this
    # request. Notice that the values for the what 
    # and where parameters come from the resources
    # we defined. We've specified for random values
    # to be used, but we could also specify sequential
    # or reverse sequential values (see XML API).
    #
    param :what  => random(:search_terms)
    param :where => random(['Toronto', 'Vancouver', 'Montreal'])
    
    # Each request can also include one or more 
    # optional response blocks. These blocks determine
    # what should happen when the specified HTTP
    # status code is returned by the web server. 
    # 
    # For successful responses, we want to parse out
    # some data from the page. For 404 (Not Found)
    # responses, we simply want the virtual user to
    # quit the usecase altogether. 
    #
    response 200 do
      
      # If the response contains HTML, it will
      # automatically be parsed using the Ruby
      # library Nokogiri. See the following link
      # for more information:
      # http://nokogiri.rubyforge.org/nokogiri/
      #
      # The important thing to note is that you 
      # don't need to write complex regular 
      # expressions to grab data from the page. 
      # 
      listing = doc.css('div.listing').first
      
      # Here we grab the first listing ID on the
      # page and store it in a variable called
      # :lid. This is similar to a resource. 
      #
      set :lid, listing['id'].match(/(\d+)/)[0]
    end
    response 404 do 
      quit "No results"
    end
  end
  
  # Notice the special variable in this URI path. 
  # Since we have defined a variable with the same
  # name in the previous request, the variable in 
  # the request will automatically be replaced with 
  # that value. This value is unique for each virtual
  # user.
  #
  get "/listing/:lid" do 
    desc "Selected listing"
    wait 1..8       
  end               
  
end

usecase 25, "YAML API" do
  
  get '/listings.yaml', "View All" do
    response 200 do
    
      # We showed above how HTML is parsed automatically.
      # Stella can do the same with XML, YAML, and JSON. 
      #
      # A variable called "doc" contains the parsed YAML.
      # "collect" is a Ruby method that iterates through 
      # all items in an Array and returns a new Array 
      # containing the return values from each iteration. 
      # Each item item is available in the variable 
      # called 'l'. 
      #
      # The variable called "listings" will contain all
      # listing ids in the YAML document.
      #
      listings = doc.collect! { |l|; l[:id]; }
      
      # And here we store that list of ids. 
      #
      set :listing_ids, listings
    end
  end
  
  # In the Simple Search usecase we stored a listing
  # id in a variable called :lid. This time we have
  # an Array of listing ids but we only want to use
  # one for each request so we override the automatic
  # variable replacement by using the param method. 
  #
  get "/listing/:lid.yaml", "Select Listing" do
    
    # Each request will use a new value from the 
    # Array and these will be selected sequentially. 
    # Note that this is _per virtual user_. Each 
    # vuser will have its own copy of the Array and
    # iterate through it independently.
    #
    param :lid => rsequential(:listing_ids)
    
    # We can use response blocks to affect behaviour 
    # the user. Here we specify that every virtual
    # user should repeat this request 20 times.
    #
    response 200 do
      repeat 7
    end
  end
  
end

usecase 10, "Self-serve API" do
  
  # Here is an example of using a POST request. 
  # Notice that the definition is otherwise 
  # identical to the ones you've seen above.
  #
  post "/listing/add", "Add a listing" do
    wait 1..4 
    param :name => random(8)
    param :city => random(['Toronto', 'Vancouver', 'Montreal'])
    param :logo => file('logo.png')
    response 302 do
      repeat 3
    end
  end
  
end

# a5689bb64829d2dc1e9ab8901223cc90c975fe3a