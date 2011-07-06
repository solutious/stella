require 'thread'

module Drydock
  module Screen
    extend self
    
    @@mutex = Mutex.new
    @@output = StringIO.new
    @@offset = 0
    
    def print(*msg)
      @@mutex.synchronize do
        @@output.print *msg
      end
    end
    
    def puts(*msg)
      @@mutex.synchronize do
        @@output.puts *msg
      end
    end
    
    def flush
      @@mutex.synchronize do
        #return if @@offset == @@output.tell
        @@output.seek @@offset
        STDOUT.puts @@output.read unless @@output.eof?
        @@offset = @@output.tell
      end
    end
    
  end
end