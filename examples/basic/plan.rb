desc "The Basic Testplan"

usecase 60, "Simple search" do
  #userpool :anonymous
  #httpauth :stella, :stella
  
  get "/", "Homepage" do
    wait 1
  end
  
  get "/search", "Search Results" do
    wait 3
    param :what  => 'food'
    param :where => 'vancouver'
    response 200 do
      #headers
      #body
      #html
    end
  end
  
  get "/listing/:lid.yaml" do
    desc "Selected listing"
    wait 3
  end
        
end

usecase 40, "Direct to listing" do
  
  get "/listing/:lid" do
    #param :lid => random[:lid]
    param :lid => "1999"
    desc "Select listing"
    wait 5
  end
end

