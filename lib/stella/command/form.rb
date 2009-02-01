
require 'httpclient'

require 'util/httputil'

require 'stella/command/base'
require 'stella/data/http'


module Stella::Command #:nodoc: all
  class Form < Drydock::Command #:nodoc: all
    include Stella::Command::Base
    
    
    
  end
end




__END__

headers = { 'Content-Type' => 'text/xml' }
                       
@client = HTTPClient.new('http://localhost:3114')
@url = URI.parse "http://solutious.com/"
#@url = URI.parse 'https://delaagsterekening.nl/api/suggestions/status.json?token=253'
#@client.set_auth("https://delaagsterekening.nl/", "stella", "stella")
@client.set_cookie_store("/tmp/cookie.dat")
body, resp = @client.get @url, headers
body.header.all.each do |h|
  puts "#{h[0]}: #{h[1]}"
end
#puts @client
@client.save_cookie_store