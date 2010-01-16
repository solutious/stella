# Stella Test Plan - Exception Handling (2009-10-08)
#
# TO BE DOCUMENTED. 
# 
# If you're reading this, remind me!
#

usecase "Exception Handling" do
  
  get "/search", "Search Results" do
    param :what  => 'No Such Listing'
    param :where => "<%= random(['Toronto', 'Montreal', 'Vancouver']) %>"
    response 404 do
      fail "No results"
    end
  end
  
end

# 0f354b3579e6c5b5b3f303aabb2ac3aa5b11096a