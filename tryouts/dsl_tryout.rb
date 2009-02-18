$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Make sure our local lib is first in line

# A Tryout for Stella's Domain specific language 
#


# TODO: prepend instance variables with "stella_"
# TODO: is it possible to use "get" inside response blocks?
# TODO: implement session handling
# BUG: http://jira.codehaus.org/browse/JRUBY-2992

require 'yaml'

require 'stella'
include Stella::DSL


environment :development do
  machines "localhost:3114"
end

testplan :dsl_tryout do
  desc "A basic demonstration of the testplan DSL"
  protocol :http
  auth :basic, "stella", "stella"
  
  post "/upload" do
    name "Add Product"
    body "bill", "/path/2/file"
    header "X-Stella" => "Yay!"
    param :convert => true
    param :rand => rand
    
    response 200, 201 do |headers, body|
      data = YAML.load(body)
      @product_id = data[:id]
    end
  end
  
  get "/product" do
    name "View Product"
    param 'id' => @product_id
    
    response 200 do |header, body|
      data = YAML.load(body)
      #repeat :times => 1, :wait => 2
    end
  end

  get "/product/22" do
    response 200 do |header, body|
      data = YAML.load(body)
    end
  end

end


functest :integration do
  plan :dsl_tryout
  verbose  
end

loadtest :moderate do
  plan :dsl_tryout
  clients 1        # <= machines * 100
  repetitions 10
  #duration 1.seconds  
  verbose
end

# Run functional test
#run :development, :integration

# Run load test
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

