#!/usr/bin/ruby

# Stella Test DSL - Example 1: Multiple requests, with response data
# 
# To run the example test, do the following:
# 
# * run bin/example_webapp.rb in an other terminal window. This provides
# an HTTP server for this script to run against. 
# 
# * Uncomment one of the run commands at the bottom of this file.
#
# * run bin/example_test.rb and watch the output!
#
#
# NOTE: The test and the web app will be running on your machine. If you
# run a heavy duty test, you're machine will be slow and possibly not
# responsive!
#

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Put the local lib first in line

require 'stella'
require 'yaml'

include Stella::DSL

testplan :dsl_example1 do
  desc "A basic demonstration of the testplan DSL"
  protocol :http
  auth :basic, "stella", "stella"
  
  post "/upload" do
    name "Add Product"
    body "bill", "/path/2/file.txt"
    header "X-Stella" => "Version #{Stella::VERSION}"
    param :convert => true
    param :rand => rand
    
    response 200, 201 do |headers, body, objid|
      data = YAML.load(body)
      @product_id = data[:id]             # Store the response value
    end
  end
  
  get "/product" do
    name "View Product"
    param 'id' => @product_id             # Use the value from the previous request
    
    response 200 do |header, body, objid|
      data = YAML.load(body)
      repeat :times => 2, :wait => 1      # Repeat this request
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
  clients 2
  repetitions 10             # Specify the number of times to execute the plan
  #duration 1.minutes        # OR the total duration of the test (not both)
  verbose
end

# Uncomment one of the following:

#run :development, :integration     # Run functional test
#run :development, :moderate        # Run load test

