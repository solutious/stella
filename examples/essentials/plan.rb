# 4f61ac3d5607139350b50335ca59a34d04b34ec7

desc "Business Finder Testplan"

usecase 65, "Simple search" do
  resource :search_terms, list('search_terms.csv')
  
  get "/", "Homepage" do
    wait 1..5
    response 200 do
      status                       # => 200
      headers['Content-Type']      # => ['text/html']
      body                         # => <html>...
      doc                          # => Nokigiri::HTML::Document
    end
  end
  
  get "/search", "Search Results" do
    wait 2..5
    param :what  => random(:search_terms)
    param :where => random(['Toronto', 'Montreal'])
    response 200 do
      listing = doc.css('div.listing').first
      set :lid, listing['id'].match(/(\d+)/)[0]
    end
    response 404 do 
      quit "No results"
    end
  end
  
  get "/listing/:lid" do           # URIs can contain variables.
    desc "Selected listing"        # This one will be replaced by
    wait 1..8                      # the one stored in the previous
  end                              # request.
  
end

xusecase 10, "Self-serve" do
  post "/listing/add", "Add a listing" do
    wait 1..4 
    param :name => random(8)
    param :city => sequential("Montreal", "Toronto", "Vancouver")
    param :logo => file('logo.png')
    response 302 do
      repeat 3
    end
  end
end

xusecase "Listing API" do
  
  get '/listings.yaml', "View All" do
    response 200 do
      # doc contains the parsed YAML object
      listings = doc.collect! { |l|; l[:id]; }
      set :current_listing_ids, listings
    end
  end
  
  get "/listing/:lid.yaml", "Select (sequential)" do
    param :lid => rsequential(:current_listing_ids)
    response 200 do
      repeat 7
    end
  end
  
end

