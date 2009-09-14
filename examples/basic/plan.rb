desc "The Basic Testplan"

usecase 60, "Simple search" do
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
    param :name => "Heavenly trucks #{rand(1000000)}"
    param :city => "Vancouver"
    response 200 do
      puts body
    end
  end
end

usecase 40, "Direct to listing" do
  resource :listing_ids, list('listing_ids.csv')
  get "/listing/:lid.yaml" do
    desc "Select listing"
    param :lid => random(1000..1007)
  end
end

