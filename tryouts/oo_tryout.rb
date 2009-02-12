$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib')) # Make sure our local lib is first in line

require 'json'

require 'stella'


tp = Stella::TestPlan.new(:suggestions_api)
tp.protocol = :https
tp.servers << "delaagsterekening.nl"

puts tp.protocol

# STEP 1
req = Stella::Data::HTTPRequest.new("/api/analyses.json", :POST)
req.body = "/Users/delano/Projects/git/stella/docs/dated/2009-q1/dlr/orange_04.pdf", "bill[uploaded_data]"
req.add_header "X-Stella", "Yay!"
req.add_param :token => @token if @token 
req.add_response(200, 201) do |headers, body|
  puts headers["Set-Cookie"]
  puts body.inspect
  data = JSON::load(body)
  @token = 1000 #data['token']
  puts "TOKEN1: #{@token}"
end
tp.add_request(req)

# STEP 2
req = Stella::Data::HTTPRequest.new("/api/suggestions.json", :POST)
req.add_param :token => @token
req.add_response(200, 201) do |headers, body|
  #puts headers["Set-Cookie"]
  #puts body.inspect
  #data = JSON::load(body)
  @token = 1000 #data['token']
  puts "TOKEN2: #{@token} (#{self})"
end
tp.add_request(req)


ft = Stella::FunctionalTest.new(:integration)
ft.testplan = tp
ft.run


