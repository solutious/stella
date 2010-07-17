require 'rubygems'
require 'em-http'

# TEST 1
@ret = :poop
EventMachine.run {
  multi = EventMachine::MultiRequest.new

  # add multiple requests to the multi-handler
  multi.add(EventMachine::HttpRequest.new('http://www.google.com/').get)
  multi.add(EventMachine::HttpRequest.new('http://www.yahoo.com/').get)

  multi.callback  {
    ret = multi.responses[:succeeded]
    multi.responses[:failed]

    EventMachine.stop
  }
}
# => @ret.class

# TEST 2
a = 1
# => 1
