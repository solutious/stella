$: << File.dirname(__FILE__)

require 'spec-helper'
require 'stella'
require 'mongrel'


describe "Stella::Command::LoadTest" do
  WORKDIR = File.join(STELLA_HOME, 'test-spec-tmp')
  
  before(:all) do
    Stella.debug = false  
  end
  
  after(:all) do
  end
  
  after(:each) do
    FileUtils.remove_dir(WORKDIR) if File.exists? WORKDIR
  end
  
  xit "should start a local test server" do
    server = Mongrel::HttpServer.new("127.0.0.1", @port)
    handler = TestHandler.new
    server.register("/test", handler)
    server.run
    sleep 12
    server.stop(true)
  end
  
  xit "should run a local performance test with Apache Bench" do
    
    arguments = %w{-c 1 -n 1 http://127.0.0.1:5600/}
    adapter = Stella::Adapter::ApacheBench.new
    adapter.process_options(arguments)
    
    testdef = Stella::Test::Definition.new
    testdef.message = "This is a build test"
    
    lt = Stella::LocalTest.new
    lt.working_directory = WORKDIR
    lt.format = 'yaml'
    lt.adapter = adapter
    lt.testdef = testdef
    stdout = capture(:stdout) do
      lt.run
    end
  end
  
  xit "should run in quiet mode"
  xit "should run with specified agents"
  xit "should run with a warmup"
  xit "should run with a specific number of test repetitions"
  xit "should accept a sleep period between test runs"
  
end

