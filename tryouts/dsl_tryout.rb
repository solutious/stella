$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Make sure our local lib is first in line

# See: http://poignantguide.net/dwemthy/
# See: http://blog.jayfields.com/search/label/DSL
# See: http://expectations.rubyforge.org/

require 'yaml'

require 'stella'
include Stella::DSL::TestPlan
include Stella::DSL::FunctionalTest
include Stella::DSL::LoadTest
#extend Stella::DSL::TestPlan
#extend Stella::DSL::FunctionalTest


testplan :dsl_tryout do
  protocol :http
  servers "localhost:5600"
  auth :basic, "stella", "stella"
  session :on
  proxy "http://localhost:3114", "user", "pass"


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
      repeat :times => 2, :wait => 1
    end
  end
  
  get "/product/22" do
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

loadtest :moderate do
  plan :suggestions_api
  users 5
  rampup :interval => 5, :max => 25, :delay => 10 # seconds
  duration 60 # minutes
end

# Run functional test
run :integration



__END__

users :anonymous do
  set :global_var => true
  user do
    set 'bill[uploaded_data]' => 'path/2/pdf'
  end
  # ...
end
