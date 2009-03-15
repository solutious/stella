#!/usr/bin/env ruby -w
# simple_client.rb
# A simple DRb client

require 'drb'

DRb.start_service

# attach to the DRb server via a URI given on the command line
remote_array = DRbObject.new [], ARGV.shift

puts remote_array.size

remote_array << 1

puts remote_array.size

__END__
# Fastthread patches: http://blog.phusion.nl/2009/02/02/getting-ready-for-ruby-191/
# <link rel="canonical" href="http://www.seomoz.org/blog">

require 'rubygems'
require 'eventmachine'

module Echo
  def receive_data data
    send_data data
  end
end

EM.run {
  EM.start_server "0.0.0.0", 10000, Echo
}



__END__
class DSL
  # Get a metaclass for this class
  def self.metaclass; class << self; self; end; end
  
  metaclass.instance_eval do
    define_method( :'POST /api/suggestions.json' ) do |val|
      puts val
    end
  end

  
end

class Runner
  attr_accessor :poop
  def hi
    @poop = :rock
  end
end

c=Runner.new

c.instance_eval do
  hi
  puts @poop
end
 
#DSL.send(:'POST /api/suggestions.json', :hi)