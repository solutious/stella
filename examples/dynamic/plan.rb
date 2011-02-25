# Stella Test Plan - Dynamic Data (2009-11-28)
#
#
# 1. START THE EXAMPLE APPLICATION
# 
# This test plan is written to work with the
# example application that ships with Stella. 
# See:
#
# $ stella example
#
#
# 2. RUN THE TEST PLAN
#
# $ stella verify -p examples/dynamic/plan.rb http://127.0.0.1:3114/
# 
# $ stella generate -c 2 -r 2 -p examples/dynamic/plan.rb http://127.0.0.1:3114/
#
usecase "Dynamic Data" do
  
  # Specify HTTP Authentication (Basic or Digest). 
  # Specify a username, password, and optional value
  # to use for the authentication domain. If no domain
  # is specifed, the root URI will be used. 
  #http_auth :user, :password, 'http://domain/'
  
  # Retrieve a list of listings and store
  # them in a resource called listing_ids.
  get '/listings.yaml', "Get Listings" do
    response 200 do
      listings = doc.collect! { |l|; l[:id]; }
      set :listing_ids, listings[0..2]
    end
  end
  
  # Access each listing page in the order
  get "/listing/:lid.yaml", "Sequential" do
    param :lid => sequential(:listing_ids)
    response 200 do
      repeat 5
    end
  end
  
  # Access each listing page in reverse order
  get "/listing/:lid.yaml", "Reverse Sequential" do
    param :lid => rsequential(:listing_ids)
    response 200 do
      repeat 5
    end
  end
 
  # Access listing pages in random order
  get "/listing/:lid.yaml", "Random" do
    param :lid => random(:listing_ids)
    response 200 do
      repeat 5
    end
  end
   
end