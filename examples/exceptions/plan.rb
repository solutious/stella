# Stella Test Plan - Exception Handling
#
# TO BE DOCUMENTED. 
# 
# If you're reading this, remind me!
#

usecase "Exception Handling" do
  
  get "/search", "Search Results" do
    param :what  => 'No Such Listing'
    param :where => random('Toronto', 'Montreal', 'Vancouver')
    response 404 do
      raise NoSearchResults
    end
  end
  
end