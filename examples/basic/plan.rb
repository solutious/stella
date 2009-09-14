desc "The Basic Testplan"

usecase "Simple search" do
  #userpool :anonymous
  #httpauth :stella, :stella
  
  get "/", "Homepage" do
    wait 1
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
    response 200 do
      puts body
    end
  end
end

usecase "Direct to listing" do
  resource :listing_ids, list('listing_ids.csv')
  get "/listing/:lid.yaml" do
    desc "Select listing"
    param :lid => random(:listing_ids)
    response 200 do
      sleep 1 and repeat 4
    end
  end
end

