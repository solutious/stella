$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Make sure our local lib is first in line

require 'yaml'

require 'stella'


tp = Stella::TestPlan.new(:oo_tryout)
tp.protocol = :http
tp.servers << "localhost:3114"

# STEP 1
req = Stella::Data::HTTPRequest.new("/upload", :POST)
req.body = "a.pdf", "bill"
req.add_header "X-Stella", "Yay!"
req.add_response(200, 201) do |headers, body|
  puts headers["Set-Cookie"]
  puts body.inspect
  data = YAML::load(body)
  @product_id = data['id']
  puts "ID: #{@product_id}"
end
tp.add_request(req)


ft = Stella::FunctionalTest.new(:oo_tryout)
ft.testplan = tp
ft.run


