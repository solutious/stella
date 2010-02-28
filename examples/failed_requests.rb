
usecase "Failed Requests" do
  
  get "/" do
    param :req => 1   # success
    header :poop => 99
  end
  
  get "/badpath" do
    param :req => 2   # failed
  end
  
  get "/badpath" do
    param :req => 3
    header :poop => 99
    response 404 do   # success
    end
  end
  
  get "/badpath" do
    param :req => 4
    response 404 do   # failed
      fail
    end
  end
  
  get "/badpath" do
    param :req => 5
    response do       # success
    end
  end
  
end