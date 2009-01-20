$: << File.dirname(__FILE__)
require 'spec-helper'
require 'mongrel'
require 'uri'
require 'net/http'

require 'stella'

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

describe "Stella::Adapter::ApacheBench" do
  WORKDIR = File.join(STELLA_HOME, 'test-spec-tmp')
  HOST = '127.0.0.1'
  PORT = 3114 + $$ % 1000
  TVUSERS = 10
  TCOUNT = 120 # This needs to be divisible evenly by TVUSERS
  TREPS = 3
  TMSG = "This is a build test"
  TEST_URI = "http://#{HOST}:#{PORT}/test"
  
  before(:all) do
  end
  
  before(:each) do
  end
  
  after(:all) do
	  # remove_dir does not seem to work on Windows
    FileUtils.remove_entry(WORKDIR, true) if File.exists? WORKDIR
  end
  
  it "start a local test server" do
    begin
      capture(:stdout) do
        @server = Mongrel::HttpServer.new(HOST, PORT)
        @handler = TestHandler.new
        @server.register("/test", @handler)
        @server.run
        res = get(TEST_URI)
        res.should.be.kind_of String
        res.split($/).first.should.equal "Stellaaahhhh!" # We can ignore the other content
      end
    rescue Interrupt
      @server.stop(true) if @server
      exit 1
    end
    
  end
  
  
  it "knows the difference between a load test and and a non-load test call" do
    ab = ApacheBench.new()
    ab.loadtest?.should.equal false
    ab.add_uri TEST_URI
    ab.loadtest?.should.equal true
    
    
  end
  
end

describe "Stella::Adapter::Siege" do

  before(:all) do
  end
  
  before(:each) do
  end

  
end