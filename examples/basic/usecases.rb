
usecase 60 do
  name "Simple search"
  #userpool :anonymous
  #httpauth :stella, :stella

  get "/" do
    name "Enter homepage"
    wait 1
  end
  
  get "/search" do
    name "Search"
    wait 3
    
    param :what  => 'food'
    param :where => 'vancouver'
    
    response 200 do |header, body|
      @lid = body.scan(/listing=(\d+?)/).first
    end
  end
  
  get "/listing/:lid" do
    name "Select listing"
    wait 3
    
    response 200 do |header, body|
      data = YAML.load(body)
    end
  end
  
end

usecase 40 do
  name "Direct to listing"
  load :lid, 'listing_ids.csv'  # May need to be environment dependant
  
  get "/listing/:lid" do
    name "Select listing"
    wait 5
  end
end


__END__
/
/search/?what=${what}&where=${where}
/listing/


