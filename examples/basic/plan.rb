# 1f5e852e934debd56aa98552c0a9227c93006f21

desc "Business Finder Testplan"

usecase 70, "Simple search" do
  
  get "/", "Homepage" do
    wait 1..3
  end
  
  get "/search", "Search Results" do
    wait 3
    param :what  => 'Big'
    param :where => ''
    response 200 do
      listing = doc.css('div.listing').first
      set :lid, listing['id'].match(/(\d+)/)[0]
    end
  end
  
  get "/listing/:lid" do
    desc "Selected listing"
    wait 3
    response 200 do
      #status 
      #headers['Content-Type']
      #body
    end
  end
  
  post "/listing/add" do
    desc "Add a business"
    param :name => random(8)
    param :city => "Vancouver"
    response 302 do
      repeat 3
    end
  end
end

usecase 30, "Direct to listing" do
  resource :preset_listing_ids, list('listing_ids.csv')
  
  get "/listing/:lid.yaml" do
    desc "Select listing"
    param :lid => random(:preset_listing_ids)
    response 200 do
      repeat 5
    end
  end
  
  get '/listings' do
    response 200 do
      listings = doc.css('div.listing').to_a
      listings.collect! { |l|; l['id'].match(/(\d+)/)[0]; }
      set :current_listing_ids, listings
    end
  end
  
  get "/listing/:lid.yaml" do
    desc "Select listing"
    param :lid => sequential(:current_listing_ids)
    response 200 do
      repeat 7
    end
  end
  
end

