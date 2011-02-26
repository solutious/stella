# Stella Test Plan - HTTP Authentication (2011-02-26)
#
#
# 1. START THE EXAMPLE APPLICATION
# 
# This test plan is written to work with the
# example application at bff.heroku.com.
#
#
# 2. RUN THE TEST PLAN
#
# $ stella verify -p examples/httpauth/plan.rb http://bff.heroku.com/
#
usecase "Use basic HTTP authentication" do
  
  auth 'stella', 'why??'
  
  get '/admin' do
    response 401 do
      # Called if authentication fails
    end
    response 200 do
      # Called if authentication succeeds
    end
  end
  
  # You can also set the HTTP auth per request. 
  # Note that here we give an incorrect password.
  get '/admin' do
    auth 'stella', 'badpassword'
  end
  
end