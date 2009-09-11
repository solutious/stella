
usecase 60 do
  desc "Simple search"
  #userpool :anonymous
  #httpauth :stella, :stella

  get "/" do
    desc "Enter homepage"
    wait 1
  end
  
  get "/search" do
    desc "Search"
    wait 3
    
    param :what  => 'food'
    param :where => 'vancouver'
    
    response 200 do |header, body|
      @lid = body.scan(/listing=(\d+?)/).first
    end
  end
  
  get "/listing/:lid" do
    desc "Select listing"
    wait 3
    
    response 200 do |header, body|
      data = YAML.load(body)
    end
  end
  
end

usecase 40 do
  desc "Direct to listing"
  
  get "/listing/:lid" do
    param :lid => '1999'
    desc "Select listing"
    wait 5
  end
end

