
loadtest :light do
  
end

loadtest :heavy do
  users 100
  repetitions 5
  #duration 60.minutes
  warmup do
    
  end
end
