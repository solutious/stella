#!/usr/bin/ruby

# Stella Test DSL - Example 1: Multiple requests, with response data
# 
# NOTE: You need to run bin/example_webapp.rb so this test has an HTTP
# server to work its magic on.
#
#

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Make sure our local lib is first in line


require 'stella'
require 'yaml'


include Stella::DSL


testplan :dsl_example1 do
  desc "A basic demonstration of the testplan DSL"
  protocol :http
  auth :basic, "stella", "stella"
  
  
  post "/upload" do
    name "Add Product"
    body "bill", "/tmp/README.rdoc"
    header "X-Stella" => "Yay!"
    param :convert => true
    param :rand => rand
    
    response 200, 201 do |headers, body, objid|
      data = YAML.load(body)
      @product_id = data[:id]
    end
  end
  
  get "/product" do
    name "View Product"
    param 'id' => @product_id
    
    response 200 do |header, body, objid|
      data = YAML.load(body)
      #repeat :times => 1, :wait => 2
    end
  end

  get "/product/22" do
    name "Product 22"
    response 200 do |header, body, objid|
      data = YAML.load(body)
    end
  end

end

# Environments 
#
# Stella can execute the same test plan on different environments.
# You can specify several environment blocks by giving them unique
# names. Each environment can contain any number of machines. 
environment :development do
  machines "localhost:3114"  
  # machine "localhost:3115"
  # ...
end

# Functional Test
#
# A functional test executes the test plan with a single client. It 
# produces more output than a load test which can be used to verify 
# both that the test plan was written correctly and that the server
# is responding as expected for each request. 
functest :integration do
  plan :dsl_example1
  verbose  2
end

# Load Test
#
# A load test executes the test plan with 1 or more clients over a
# period of time. 
loadtest :moderate do
  plan :dsl_example1
  clients 2        # <= machines * 100
  repetitions 10
  #duration 1.seconds  
  verbose
end

# Uncomment one of the following:

#run :development, :integration     # Run functional test
#run :development, :moderate        # Run load test




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

