# 1f5e852e934debd56aa98552c0a9227c93006f21

desc "Business Finder Testplan"

usecase 65, "Simple search" do
  
  get "/", "Homepage" do
    wait 1..5
  end
  
  get "/search", "Search Results" do
    wait 2..5
    param :what  => 'Big'
    param :where => ''
    response 200 do
      p doc.class
      # doc contains the parsed HTML document
      listing = doc.css('div.listing').first
      set :lid, listing['id'].match(/(\d+)/)[0]
    end
  end
  
  get "/listing/:lid" do
    desc "Selected listing"
    wait 1..8
    response 200 do
      #status 
      #headers['Content-Type']
      #body
    end
  end
  
end

usecase "YAML API" do
  resource :preset_listing_ids, list('listing_ids.csv')
  
  get "/listing/:lid.yaml", "Select listing" do
    param :lid => random(:preset_listing_ids)
    response 200 do
      repeat 5
    end
  end
  
  get '/listings.yaml', "View All" do
    response 200 do
      # doc contains the parsed YAML object
      listings = doc.collect! { |l|; l[:id]; }
      set :current_listing_ids, listings
    end
  end
  
  get "/listing/:lid.yaml", "Select listing" do
    param :lid => rsequential(:current_listing_ids)
    response 200 do
      repeat 7
    end
  end
  
end

usecase 10, "Advertiser self-serve" do
  post "/listing/add" do
    desc "Add a business"
    wait 1..4 
    param :name => random(8)
    param :city => "Vancouver"
    response 302 do
      repeat 3
    end
  end
end
