$: << File.dirname(__FILE__)

require 'spec-helper'
require 'stella'
require 'mongrel'
require 'uri'
require 'net/http'

class TestHandler < Mongrel::HttpHandler
  attr_reader :ran_test
  attr_accessor :server
  def process(request, response)
    @ran_test = true
    response.start do |head,out|
      head["Content-Type"] = "text/plain"
      results = "Stellaaahhhh!"
      out << results
    end
    
  end
end

def get(uri)
  uri = URI.parse(uri) unless uri.kind_of? URI
  Net::HTTP.get(uri)
end

describe "Stella::Command::LoadTest" do
  WORKDIR = File.join(STELLA_HOME, 'test-spec-tmp')
  HOST = '127.0.0.1'
  PORT = 3114 + $$ % 1000
  TVUSERS = 2
  TCOUNT = 142 # This needs to be divisible evenly by TVUSERS
  TREPS = 3
  TMSG = "This is a build test"
  
  
  before(:all) do
    Stella.debug = false  
  end
  
  after(:all) do
    @server.stop(true) if @server
  end
  
  after(:each) do
	  # remove_dir does not seem to work on Windows
    FileUtils.remove_entry(WORKDIR, true) if File.exists? WORKDIR
  end
  
  it "start a local test server" do
    begin
      capture(:stdout) do
        @server = Mongrel::HttpServer.new("127.0.0.1", PORT)
        @handler = TestHandler.new
        @server.register("/test", @handler)
        @server.run
        res = get("http://#{HOST}:#{PORT}/test")
        res.should.be.kind_of String
        res.should.equal "Stellaaahhhh!"
      end
    rescue Interrupt
      @server.stop(true) if @server
      exit 1
    end
    
  end
  
  it "run a local performance test with Apache Bench" do
    puts 
    adapter = Stella::Adapter::ApacheBench.new(["-c", "#{TVUSERS}", "-n", "#{TCOUNT}", "http://#{HOST}:#{PORT}/test"])
    files = %w{ab-percentiles.log ab-requests.log}
    execute_load_test(adapter, files)
  end
  
  
  it "run a local performance test with Siege (unix only)" do
    return if Stella.sysinfo.impl == :windows
    puts 
    adapter = Stella::Adapter::Siege.new(["-c", "#{TVUSERS}", "-r", "#{TCOUNT / 2}", "--benchmark", "http://#{HOST}:#{PORT}/test"])
    files = %w{siege.log siegerc}
    execute_load_test(adapter, files)
  end
  
  
  it "run a local performance test with Httperf (unix only)" do
    return if Stella.sysinfo.impl == :windows
    puts 
    adapter = Stella::Adapter::Httperf.new(["--num-conns", "#{TCOUNT}", "--rate", "0", "--uri=/test", "--server=#{HOST}", "--port=#{PORT}"])
    files = %w{}
    execute_load_test(adapter, files)
  end
  
  xit "create a symlink to the latest test directory (unix only)" do
    return if Stella.sysinfo.impl == :windows
    puts 
    adapter = Stella::Adapter::ApacheBench.new(["http://#{HOST}:#{PORT}/test"])
    lt = execute_load_test(adapter)
    File.symlink?(lt.test_path_symlink)
  end
  
  xit "run in quiet mode"
  xit "run with specified agents"
  xit "run with a warmup"
  xit "run with a specific number of test repetitions"
  xit "accept a sleep period between test runs"
  xit "create summaries in yaml"
  xit "create summaries in csv"
  xit "create summaries in json"
  
  
  
  def execute_load_test(adapter, files)
    testdef = Stella::Test::Definition.new
    testdef.message = TMSG
    testdef.repetitions = TREPS
    
    lt = Stella::LocalTest.new
    lt.working_directory = WORKDIR
    lt.adapter = adapter
    lt.testdef = testdef
    
    files ||= []
    files.push(%w{COMMAND.txt STDERR.txt STDOUT.txt SUMMARY.yaml}).flatten!
    
    begin
      
      lt.run
      lt.test_stats.transactions_total.should.equal TCOUNT * TREPS

      # The test directory was created
      File.exists?(lt.test_path).should.equal true

      # The message was recorded
      msg_path = File.join(lt.test_path, "MESSAGE.txt")
      File.exists?(msg_path).should.equal true
      File.read(msg_path).chomp.should.equal TMSG

      # And all run output files were created
      runnum = "00"
      TREPS.times do
        runnum = runnum.succ
        files.each do |file|
          file_short = File.join("run#{runnum}", file)
          file_path = File.join(lt.test_path, file_short)
          File.exists?(file_path).should.blaming("Cannot find: #{file_short}").equal true
        end
      end
      
    rescue Interrupt
      @server.stop(true) if @server
    end
    
    lt
  end
end

