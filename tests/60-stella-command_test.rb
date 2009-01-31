$: << File.dirname(__FILE__)

require 'spec-helper'


require 'stella'

describe "Stella::Command::LoadTest" do

  before(:all) do
    Stella.debug = false  
    @@server = Mongrel::HttpServer.new(::HOST, ::PORT)
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
        res = get("http://#{HOST}:#{PORT}/test")
        res.should.be.kind_of String
        res.split($/).first.should.equal "Stellaaahhhh!" # We can ignore the other content
      end
    rescue Interrupt
      @@server.stop(true) if @@server
      exit 1
    end
    
  end
  
  it "run a local performance test with Apache Bench" do
    puts 
    testdef = Stella::Test::Definition.new
    adapter = Stella::Adapter::ApacheBench.new(["-c", "#{TVUSERS}", "-n", "#{TCOUNT}", "http://#{HOST}:#{PORT}/test"])
    lt = Stella::Command::LocalTest.new
    files = %w{ab-percentiles.log ab-requests.log}
    execute_load_test(lt, testdef, adapter, files)
    lt.test_stats.transactions_total.should.equal TCOUNT * TREPS
  end
  
  
  it "run a local performance test with Siege (unix only)" do
    return if Stella.sysinfo.impl == :windows
    puts 
    testdef = Stella::Test::Definition.new
    adapter = Stella::Adapter::Siege.new(["-c", "#{TVUSERS}", "-r", "#{TCOUNT / TVUSERS}", "--benchmark", "http://#{HOST}:#{PORT}/test"])
    lt = Stella::Command::LocalTest.new
    files = %w{siege.log siegerc}
    execute_load_test(lt, testdef, adapter, files)
    lt.test_stats.transactions_total.should.equal TCOUNT * TREPS
  end
  
  
  it "run a local performance test with Httperf (unix only)" do
    return if Stella.sysinfo.impl == :windows
    puts 
    testdef = Stella::Test::Definition.new
    adapter = Stella::Adapter::Httperf.new(
      ["--wsess=#{(TCOUNT / TVUSERS).to_i},#{TVUSERS},0", "--rate=#{TCOUNT / TVUSERS}", "--uri=/test", "--server=#{HOST}", "--port=#{PORT}"]
    )
    lt = Stella::Command::LocalTest.new
    files = %w{}
    execute_load_test(lt, testdef, adapter, files)
    lt.test_stats.transactions_total.should.equal TCOUNT * TREPS
  end
  
  it "create a symlink to the latest test directory (unix only)" do
    return if Stella.sysinfo.impl == :windows
    puts 
    testdef = Stella::Test::Definition.new
    adapter = Stella::Adapter::ApacheBench.new(["-c", TVUSERS.to_s, "-n", TCOUNT.to_s, "http://#{HOST}:#{PORT}/test"])
    lt = Stella::Command::LocalTest.new
    execute_load_test(lt, testdef, adapter)
    File.symlink?(lt.test_path_symlink).should.equal true
    lt.test_stats.transactions_total.should.equal TREPS * TCOUNT
  end
  
  it "run in quiet mode" do
    puts 
    testdef = Stella::Test::Definition.new
    adapter = Stella::Adapter::ApacheBench.new(["-c", TVUSERS.to_s, "-n", TCOUNT.to_s, "http://#{HOST}:#{PORT}/test"])
    lt = Stella::Command::LocalTest.new
    lt.quiet = true
    output = capture(:stdout) do
      execute_load_test(lt, testdef, adapter)
    end
    output.split($/).size.should.equal 2
    lt.test_stats.transactions_total.should.equal TREPS * TCOUNT
  end
  
  Stella::Storable::SUPPORTED_FORMATS.each do |format|
	  next if format == 'json' && !HAS_JSON
    it "create summaries in #{format}" do
      puts 
      testdef = Stella::Test::Definition.new
      adapter = Stella::Adapter::ApacheBench.new(["-c", TVUSERS.to_s, "-n", TCOUNT.to_s, "http://#{HOST}:#{PORT}/test"])
      lt = Stella::Command::LocalTest.new
      lt.format = format
      execute_load_test(lt, testdef, adapter)
      File.exists?(File.join(lt.test_path, "STATS.#{format}")).should.equal true
      lt.test_stats.transactions_total.should.equal TREPS * TCOUNT
    end
  end
  
  it "run with a warmup with a 50% load factor" do
    puts
    testdef = Stella::Test::Definition.new
    adapter = Stella::Adapter::ApacheBench.new(["-c", TVUSERS.to_s, "-n", TCOUNT.to_s, "http://#{HOST}:#{PORT}/test"])
    lt = Stella::Command::LocalTest.new
    testdef.warmup = 0.5  # this means half of the number of requests
    execute_load_test(lt, testdef, adapter)
    File.exists?(File.join(lt.test_path, "STATS.yaml")).should.equal true
    
    summary_file = File.join(lt.test_path, "warmup", "SUMMARY.yaml")
    File.exists?(summary_file).should.blaming("Summary file").equal true
    summary = Stella::Test::Run::Summary.from_file(summary_file)
    summary.transactions.should.blaming("Warmup transaction count").equal(TCOUNT * 0.5)
    lt.test_stats.transactions_total.should.equal TREPS * TCOUNT
  end
  
  it "run with a rampup" do  
    puts
    testdef = Stella::Test::Definition.new
    adapter = Stella::Adapter::ApacheBench.new(["-c", TVUSERS.to_s, "-n", TCOUNT.to_s, "http://#{HOST}:#{PORT}/test"])
    lt = Stella::Command::LocalTest.new
    testdef.rampup = [TVUSERS,TVUSERS*2]
    execute_load_test(lt, testdef, adapter)
    File.exists?(File.join(lt.test_path, "STATS.yaml")).should.equal true
    lt.rampup_test_stats.transactions_total.should.equal TREPS * (TCOUNT) + (TREPS * TCOUNT*2)
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
  def execute_load_test(lt, testdef, adapter, files=nil)
    testdef.message = TMSG
    testdef.repetitions = TREPS
    
    lt.working_directory = WORKDIR
    lt.adapter = adapter
    lt.testdef = testdef
    
    files.push(%w{COMMAND.txt STDERR.txt STDOUT.txt}).flatten! unless files.nil?
    
    begin
      
      lt.run
      
      lt.test_stats.should.be.instance_of Stella::Test::Stats
      
      %w{
        elapsed_time_avg throughput_avg response_time_avg 
        response_time_avg transaction_rate_avg vusers_avg
        data_transferred_total transactions_total elapsed_time_total
      }.each do |field|
        lt.test_stats.send(field).should.blaming("Field: #{field}").be > 0
      end
      
      %w{
        elapsed_time_sdev throughput_sdev transaction_rate_sdev
        vusers_sdev response_time_sdev
      }.each do |field|
        lt.test_stats.send(field).should.blaming("Field: #{field}").be >= 0
      end

      total_check = lt.test_stats.failed_total + lt.test_stats.successful_total
      total = lt.test_stats.transactions_total
      
      total.should.blaming("Successful and Failed transaction count").equal total_check
      lt.test_stats.availability.should.blaming("Field: availability").equal 100
      
      unless files.nil? 
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
      end
      
    rescue Interrupt
      @server.stop(true) if @server
    end
    
    lt
  end
end

