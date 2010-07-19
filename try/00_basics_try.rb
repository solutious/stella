require 'rubygems'
require 'em-http'
require 'pp'
##
@ret = :poop
EventMachine.run {
  multi = EventMachine::MultiRequest.new

  # add multiple requests to the multi-handler
  #multi.add(EventMachine::HttpRequest.new('http://www.google.com/').get)
  multi.add(EventMachine::HttpRequest.new('http://www.yahoo.com/').get)

  multi.callback  {
    @ret = multi.responses[:succeeded]
    pp @ret
    multi.responses[:failed]

    EventMachine.stop
  }
}
@ret
# => @ret

# TEST 2
a = 1
# => 1

GET /
X-An-Header: 100px

GET /login?

