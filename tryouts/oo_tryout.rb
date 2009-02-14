$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Make sure our local lib is first in line

require 'json'

require 'stella'


tp = Stella::TestPlan.new(:suggestions_api)
tp.protocol = :http
tp.servers << "localhost:3114"

puts tp.protocol

# STEP 1
req = Stella::Data::HTTPRequest.new("/upload", :POST)
req.body = "a.pdf", "bill"
req.add_header "X-Stella", "Yay!"
req.add_param :token => @token if @token 
req.add_response(200, 201) do |headers, body|
  puts headers["Set-Cookie"]
  puts body.inspect
  data = JSON::load(body)
  @product_id = data['id']
  puts "ID: #{@product_id}"
end
tp.add_request(req)


ft = Stella::FunctionalTest.new(:integration)
ft.testplan = tp
ft.run


