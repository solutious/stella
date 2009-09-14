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
      d
      #status 
      #headers['Content-Type']
      #body
    end
  end
        
end

usecase 40, "Direct to listing" do
  get "/listing/:lid.yaml" do
    #param :lid => random[:lid]
    param :lid => "1999"
    desc "Select listing"
  end
end

