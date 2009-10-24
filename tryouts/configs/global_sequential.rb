
usecase "Global Sequential" do
  
  get "/" do
    param :req => 1
    param :a => sequential([1,2,3])
    param :b => sequential([4,5,6])
    param :c => sequential([7,8,9])
  end
  
  get "/" do
    param :req => 2
    param :a => rsequential([33,22,11])
    param :b => rsequential([66,55,44])
    param :c => rsequential([99,88,77])
  end
end