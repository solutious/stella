
group "Stella"
library :stella, 'lib'
tryouts "Object Digests" do
  setup do
    #Gibbler.enable_debug
  end
  clean do
    Gibbler.disable_debug
  end
  
  dream "90199c341ea7ea4e22139e690e3d68a78ec6fce3"
  drill "Request can gibbler" do
    r = Stella::Data::HTTP::Request.new :get, '/'
    r.digest
  end
  
  dream "9ef5fb0707526e47547b3e6a59d8d3e3de64667f"
  drill "Usecase can gibbler" do
    u = Stella::Testplan::Usecase.new 
    u.digest
  end
  
  dream "0d5d6ac215563f09d4143d7e1ca9ac0611cc164d"
  drill "Testplan can gibbler" do
    t = Stella::Testplan.new 'localhost'
    t.digest
  end
  
  dream "a04e699bf8d354c68101ae62bf3e4f32fbae3221"
  drill "Complex Testplan can gibbler" do
    u = Stella::Testplan::Usecase.new 
    r = u.add_request :get, '/', 'homepage'
    r.param :user => :name
    t = Stella::Testplan.new 'localhost'
    t.add_usecase u
    t.digest
  end
  
end


