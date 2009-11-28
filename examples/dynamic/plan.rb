
usecase "Dynamic Data" do
  
  get '/listings.yaml', "Get Listings" do
    response 200 do
      listings = doc.collect! { |l|; l[:id]; }
      set :listing_ids, listings[0..2]
    end
  end
  
  xget "/listing/:lid.yaml", "Sequential" do
    param :lid => sequential(:listing_ids)
    response 200 do
      repeat 5
    end
  end
  
  xget "/listing/:lid.yaml", "Reverse Sequential" do
    param :lid => rsequential(:listing_ids)
    
    response 200 do
      repeat 5
    end
  end
 
  get "/listing/:lid.yaml", "Random" do
    param :lid => random(:listing_ids)
    param :path => path('hello.txt')
    response 200 do
      repeat 5
    end
  end
   
end