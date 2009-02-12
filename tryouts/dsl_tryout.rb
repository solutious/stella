$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Make sure our local lib is first in line

# See: http://poignantguide.net/dwemthy/
# See: http://blog.jayfields.com/search/label/DSL
# See: http://expectations.rubyforge.org/

require 'yaml'

require 'stella'
include Stella::DSL::TestPlan
include Stella::DSL::FunctionalTest
#extend Stella::DSL::TestPlan
#extend Stella::DSL::FunctionalTest


testplan :dsl_tryout do
  protocol :http
  servers "localhost:5600"
  auth :basic, "stella", "stella"
  #session :on
  #proxy "http://localhost:3114", "user", "pass"


  post "/upload" do
    body "bill[uploaded_data]", "content"
    header "X-Stella", "Yay!"
    param :convert => true
    param :rand => rand
    
    response 200, 201 do |headers, body|
      data = YAML.load(body)
      @product_id = data[:id]
      puts "ID: #{data[:id]}"
    end
  end
  
  xget "/product" do
    param 'id' => @product_id
    
    response 200 do |header, body|
      data = YAML.load(body)
      puts "ID: #{data[:id]}"
      repeat :times => 2, :wait => 1
    end
  end
  
  xget "/product/22" do
    response 200 do |headers, body|
      data = YAML.load(body)
      puts "ID: #{data[:id]}"
    end
  end
  
end

functest :integration do
  plan :dsl_tryout
  verbose
end


run :integration


