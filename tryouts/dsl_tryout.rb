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
  #session :on
  #proxy "http://localhost:3114", "user", "pass"
  
  post "/upload" do
    body "/Users/delano/Projects/git/stella/docs/dated/2009-q1/dlr/orange_04.pdf", "bill[uploaded_data]"
    header "X-Stella", "Yay!"
    param :convert => true
    param :rand => rand
    
    response 200, 201 do |headers, body|
      data = YAML.load(body)
      @product_id = data[:id]
      puts "ID: #{data[:id]}"
    end
  end
  

end

functest :integration do
  plan :dsl_tryout
end


run :integration


