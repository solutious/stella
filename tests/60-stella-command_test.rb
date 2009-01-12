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

at_exit do
  @server.stop(true) if @server
end

describe "Stella::Command::LoadTest" do
  WORKDIR = File.join(STELLA_HOME, 'test-spec-tmp')
  HOST = '127.0.0.1'
  PORT = 3114 + $$ % 1000
  TVUSERS = 2
  TCOUNT = 2 # This needs to be divisible evenly by TVUSERS
  TREPS = 2
  TMSG = "This is a build test"
  
  
  before(:all) do
    Stella.debug = false  
  end
  
  
  after(:each) do
	  # remove_dir does not seem to work on Windows
    #FileUtils.remove_entry(WORKDIR, true) if File.exists? WORKDIR
  end
  
  it "start a local test server" do
    begin
      capture(:stdout) do
        @server = Mongrel::HttpServer.new(HOST, PORT)
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
    lt = Stella::LocalTest.new
    files = %w{ab-percentiles.log ab-requests.log}
    execute_load_test(lt, adapter, files)
  end
  
  
  it "run a local performance test with Siege (unix only)" do
    return if Stella.sysinfo.impl == :windows
    puts 
    adapter = Stella::Adapter::Siege.new(["-c", "#{TVUSERS}", "-r", "#{TCOUNT / 2}", "--benchmark", "http://#{HOST}:#{PORT}/test"])
    lt = Stella::LocalTest.new
    files = %w{siege.log siegerc}
    execute_load_test(lt, adapter, files)
    lt.test_stats.transactions_total.should.equal TCOUNT * TREPS
  end
  
  
  it "run a local performance test with Httperf (unix only)" do
    return if Stella.sysinfo.impl == :windows
    puts 
    adapter = Stella::Adapter::Httperf.new(["--num-conns", "#{TCOUNT}", "--rate", "0", "--uri=/test", "--server=#{HOST}", "--port=#{PORT}"])
    lt = Stella::LocalTest.new
    files = %w{}
    execute_load_test(lt, adapter, files)
    lt.test_stats.transactions_total.should.equal TCOUNT * TREPS
  end
  
  it "create a symlink to the latest test directory (unix only)" do
    return if Stella.sysinfo.impl == :windows
    puts 
    adapter = Stella::Adapter::ApacheBench.new(["http://#{HOST}:#{PORT}/test"])
    lt = Stella::LocalTest.new
    execute_load_test(lt, adapter)
    File.symlink?(lt.test_path_symlink).should.equal true
    lt.test_stats.transactions_total.should.equal 2
  end
  
  it "run in quiet mode" do
    puts 
    adapter = Stella::Adapter::ApacheBench.new(["http://#{HOST}:#{PORT}/test"])
    lt = Stella::LocalTest.new
    lt.quiet = true
    output = capture(:stdout) do
      execute_load_test(lt, adapter)
    end
    output.split($/).size.should.equal 2
    lt.test_stats.transactions_total.should.equal 2
  end
  
  Stella::Storable::SUPPORTED_FORMATS.each do |format|
    it "create summaries in #{format}" do
      puts 
      adapter = Stella::Adapter::ApacheBench.new(["http://#{HOST}:#{PORT}/test"])
      lt = Stella::LocalTest.new
      lt.format = format
      execute_load_test(lt, adapter)
      File.exists?(File.join(lt.test_path, "SUMMARY.#{format}")).should.equal true
      lt.test_stats.transactions_total.should.equal 2
    end
  end
  
  it "run with a warmup" do
    adapter = Stella::Adapter::ApacheBench.new(["-n", "100", "http://#{HOST}:#{PORT}/test"])
    lt = Stella::LocalTest.new
    lt.warmup = 0.5
    execute_load_test(lt, adapter)
    File.exists?(File.join(lt.test_path, "SUMMARY.#{format}")).should.equal true
    lt.test_stats.transactions_total.should.equal 2
  end
  
  xit "accept a sleep period between test runs"
  xit "run with specified agents"   
  
  
  # +lt+ is an instance of Stella::Command::LoadTest
  # +adapter+ is a Stella::Adapter object
  # +files+ (optional) is a list of filenames that should exist in the 
  # testrun/2009-01-01/run01 directory after a test. When files is empty
  # we return without running any tests. Note that when adding file names
  # you don't need to include the standard files (STDOUT.txt, etc...).
  # Return value is the Stella::Command::LoadTest instance
  def execute_load_test(lt, adapter, files=nil)
    testdef = Stella::Test::Definition.new
    testdef.message = TMSG
    testdef.repetitions = TREPS
    
    lt.working_directory = WORKDIR
    lt.adapter = adapter
    lt.testdef = testdef
    
    files.push(%w{COMMAND.txt STDERR.txt STDOUT.txt}).flatten! unless files.nil?
    
    begin
      
      lt.run
      
      return lt if files.nil? 
      

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

