# Stella Test Plan - Reading CSV Data (2009-10-08)
#
# TO BE DOCUMENTED.
# 
# If you're reading this, remind me!
#

usecase "Reading CSV Data" do
  resource :search_terms, csv('search_terms.csv')
  
  get "/search", "Search (random)" do
    param :what  => "random(:search_terms, 0) %>"
    param :where => "random(:search_terms, 1) %>"
  end
  
  get "/search", "Search (sequential #1)" do
    param :what  => "sequential(:search_terms, 0) %>"
    param :where => "sequential(:search_terms, 1) %>"
  end
  
  get "/search", "Search (sequential #2)" do
    param :what  => "<%= sequential(:search_terms, 0) %>"
    param :where => "<%= sequential(:search_terms, 1) %>"
  end
end

# d93df136283f3867f462266a98675ce0b2f51b08