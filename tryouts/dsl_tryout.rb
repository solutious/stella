$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Make sure our local lib is first in line

# See: http://poignantguide.net/dwemthy/
# See: http://blog.jayfields.com/search/label/DSL
# See: http://expectations.rubyforge.org/

require 'yaml'

require 'stella'
include Stella::DSL::TestPlan
include Stella::DSL::FunctionalTest


testplan :dsl_tryout do
  protocol :http
  servers "localhost:5600"
  auth :basic, "stella", "stella"

  post "/upload" do
    body "content", "bill[uploaded_data]"
    header "X-Stella", "Yay!"
    param :convert => true
    param :rand => rand
    
    response 200, 201 do |headers, body|
      data = YAML.load(body)
      @product_id = data[:id]
      puts "ID: #{data[:id]}"
    end
  end
  
  get "/product/22"
  
  get "/product" do
    param 'id' => @product_id
    
    response 200 do |header, body|
      puts body
    end
  end
  
  
end

functest :integration do
  plan :dsl_tryout
  #verbose
end


run :integration


