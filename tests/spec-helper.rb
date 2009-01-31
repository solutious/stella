
require 'rubygems'
require 'test/spec'
require 'fileutils'

require 'mongrel'
require 'uri'
require 'net/http'

unless defined? STELLA_HOME
  STELLA_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..')) 
  $:.unshift(File.join(STELLA_HOME, 'lib')) # Make sure our local lib is first in line
end

WORKDIR = File.join(STELLA_HOME, 'test-spec-tmp')
HOST = '127.0.0.1'
PORT = 3114 + $$ % 1000
TVUSERS = 10
TCOUNT = 120 # This needs to be divisible evenly by TVUSERS
TREPS = 3
TMSG = "This is a build test"
TEST_URI = "http://#{HOST}:#{PORT}/test"


# Stolen from http://github.com/wycats/thor
def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end

  result
end

def get(uri)
  uri = URI.parse(uri) unless uri.kind_of? URI
  Net::HTTP.get(uri)
end

begin
	require 'json'
rescue LoadError
	::HAS_JSON = false
else
	::HAS_JSON = true
end

# Used by the HTTP server instances used for testing. 
class TestHandler < Mongrel::HttpHandler
  attr_reader :ran_test
  attr_accessor :server
  def process(request, response)
    @ran_test = true
    response.start do |head,out|
      head["Content-Type"] = "text/plain"
      results = "Stellaaahhhh!#{$/}"
      results << 'X'*1000 # Pump up the volume (1KB)
      out << results
    end
    
  end
end
