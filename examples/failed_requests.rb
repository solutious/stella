
usecase "Failed Requests" do
  
  get "/" do
    param :req => 1   # success
  end
  
  get "/badpath" do
    param :req => 2   # failed
  end
  
  get "/badpath" do
    param :req => 3
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