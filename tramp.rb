Trample.configure do
  concurrency 200
  iterations  10
  get "http://ec2-72-44-39-57.compute-1.amazonaws.com:3114/"
  get "http://ec2-72-44-39-57.compute-1.amazonaws.com:3114/listings"
end