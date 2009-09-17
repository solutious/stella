

usecase "Exception Handling" do
  
  get "/search", "Search Results" do
    wait 2..5
    param :what  => random()
    param :where => random('Toronto', 'Montreal', 'Vancouver')
    response 200 do
      listing = doc.css('div.listing').first
      set :lid, listing['id'].match(/(\d+)/)[0]
      raise NoListingResultFound if listing.nil?
    end
    response 404 do
      raise NoSearchResults 
    end
  end
  
end