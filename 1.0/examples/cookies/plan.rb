# Stella Test Plan - Cookies (2009-10-08)
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
# $ stella verify -p examples/cookies/plan.rb http://127.0.0.1:3114/
#
desc "Cookies Examples"

usecase "Temporary Cookies" do
  
  # By default, Stella keeps temporary cookies available within 
  # a single usecase. The example application creates a cookie
  # called "bff-history" that contains the most recent search
  # terms. Before we run a search request, the cookie is empty.
  get "/", "Homepage" do
    response do
      puts "COOKIE: " << headers['Set-Cookie'].first
    end
  end
  
  # Here the cookie will contain the search term
  get "/search", "Search" do
    param :what  => random(['Big', 'Beads', 'Joe'])
    response do
      puts "COOKIE: " << headers['Set-Cookie'].first
    end
  end
  
  # And if we check the homepage again, the homepage now contains
  # a list of the most recent search terms. This shows how Stella
  # automatically sends the temporary cookie within a usecase.
  get "/", "Homepage" do
    response 200 do
      puts "You searched for: " << doc.css('ul#history a').first.content
    end
  end
  
end

# 2440c77ed4382b97fcbb3b1cfbc3be5d7ef3653f
