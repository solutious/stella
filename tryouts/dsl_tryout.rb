$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Make sure our local lib is first in line

# A Tryout for Stella's Domain specific language 
#


# TODO: prepend instance variables with "stella_"
# TODO: is it possible to use "get" inside response blocks?
# TODO: implement session handling

require 'yaml'

require 'stella'
include Stella::DSL


environment :development do
  machines "localhost:3114"
end

testplan :dsl_tryout do
  desc "A basic demonstration of the testplan DSL"
  protocol :https
  auth :basic, "stella", "stella"
  
  post "/upload" do
    body "bill", "/path/2/file"
    header "X-Stella" => "Yay!"
    param :convert => true
    param :rand => rand
    
    response 200, 201 do |headers, body|
      data = YAML.load(body)
      @product_id = data[:id]
      puts "ID: #{data[:id]}"
    end
  end
  
  get "/product" do
    param 'id' => @product_id
    
    response 200 do |header, body|
      data = YAML.load(body)
      puts "ID: #{data[:id]}"
      repeat :times => 1, :wait => 2
    end
  end

end


functest :integration do
  plan :dsl_tryout
  verbose  
end

loadtest :moderate do
  plan :dsl_tryout
  #clients 5, :anon_clients        # <= machines * 100
  #machines 1, :generic           # <= clients
  #rampup :interval => 5, :max => 25, :delay => 10 # seconds
  #duration 60 # minutes
end


puts environments

# Run functional test
run :development, :moderate



__END__


## TODO: variable interpolation. Should happen at test time so
## instance variables can be grabbed from the calling space. 
  
#  get "/product/${token}" do
#    ## TODO: Override environment settings. 
#    #protocol :https
#    response 200 do |headers, body|
#      data = YAML.load(body)
#      puts "ID: #{data[:id]}"
#    end
#  end




clients :anon_clients do
  set :global_var => true
  pattern :random   # One of: roundrobin, random (default)
  client :default do
    set 'bill[uploaded_data]' => 'path/2/pdf'
  end
  # ...
end

#environment :staging do
#  proxy "http://localhost:3114", "user", "pass"  
#  machine "localhost" do
#    port 3114
#    ssh :user, :pass, 222
#    monitoring :basic
#  end
#end

