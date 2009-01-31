$: << File.dirname(__FILE__)
require 'spec-helper'

require 'stella'

describe "Stella::Adapter::ApacheBench" do
  
  before(:all) do
    @@server = Mongrel::HttpServer.new(::HOST, PORT)
  end
  
  before(:each) do
  end
  
  after(:all) do
	  # remove_dir does not seem to work on Windows
    FileUtils.remove_entry(WORKDIR, true) if File.exists? WORKDIR
    @@server.stop(true) if @@server
  end
  
  it "start a local test server" do
    begin
      capture(:stdout) do
        
        @@server.register("/test", TestHandler.new)
        @@server.run
        res = get(TEST_URI)
        res.should.be.kind_of String
        res.split($/).first.should.equal "Stellaaahhhh!" # We can ignore the other content
      end
    rescue Interrupt
      @@server.stop(true) if @@server
      exit 1
    end
    
  end
  
  
  it "knows the difference between a load test and and a non-load test call" do
    ab = Stella::Adapter::ApacheBench.new()
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