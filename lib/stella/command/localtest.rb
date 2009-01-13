

module Stella
  class LocalTest < Stella::Command::Base

      # A container for the test parameters
    attr_accessor :testdef
      # The load tool adapter
    attr_accessor :adapter
    
    attr_accessor :test_path
    
    attr_accessor :quiet
    attr_accessor :guid
    attr_accessor :verbose
    attr_accessor :format
    
      # list of all filesystem paths for each run in a single test
    attr_reader :test_runpaths
      # same as above, expect for all tests
    attr_reader :all_runpaths
      # list of all hostname:port in the test
    attr_reader :hosts
      # list of all /paths in the test
    attr_reader :paths
    
    attr_accessor :working_directory
    attr_reader :available_agents
    attr_reader :test_stats
    attr_reader :rampup_test_stats
    
    def initialize(testdef=nil, adapter=nil)
      @testdef = testdef if testdef
      @adapter = adapter if adapter
      
      # Disabled until we resolve JRuby on OSX issue (won't load openssl)
      #@guid = Crypto.sign(rand.to_s, rand.to_s)
      
      @test_runpaths = []       
      @all_runpaths = []        
      @hosts = []               
      @paths = []
      @format = 'yaml'
      @agents = []
      @verbose = 0
      
      ua_path = File.join(STELLA_HOME, 'support', 'useragents.txt')
      Stella::LOGGER.debug("LOADING #{ua_path}")
      
      @available_agents = Stella::Util.process_useragents(ua_path)
    end
    

    def translate_requested_agents(possible_agents=[])
      agents = []
      return agents if !possible_agents || possible_agents.empty?
      
      possible_agents.each do |a|
        agents << Stella::Util.find_agent(*a)
      end
      agents
    end
    
    def run
      
      
      raise UnavailableAdapter.new(@adapter.name) unless @adapter.available?
      
      # If the adapter isn't being called for a loadtest, we don't have anything to do.
      unless @adapter.loadtest?
        system(@adapter.command)
        return
      end
            
      @agents = translate_requested_agents(@testdef.agents)
      
      @test_path = _generate_test_path
      
      prepare_test(@test_path)       
      
        threshold = (@testdef.rampup) ? @testdef.rampup.ceiling : @adapter.vusers
        
        runnum = "00"
        while(@adapter.vusers <= threshold) do
          
          # Make sure the load factor is set to 1. If there was a warmup, 
          # then this value will be less than 1.
          testrun = maker_of_testruns(1)
          
          # We empty test_runpaths so we can keep track of the runpaths for each
          # level of virtual users. This is useful during a rampup test so we can
          # collect the stats for the repetitions at each virtual user level. 
          @test_runpaths = []
          
          # Execute each test run in turn. All of the steps are the same for each
          # run. This is important because the purpose of the test runs is to 
          # create a statistical certainty of performance. 
          @testdef.repetitions.times do 
            
            # This value is used to create the run directory and show which run we're on
            runnum.succ!
            
            # Generate the filesystem path to store the run data.
            runpath = File.join(test_path, "run#{runnum}")

            # Keep track of every run path. We use this in postpare to 
            # do some stuff after all the tests have run
            @all_runpaths << runpath
            
            # test_runpaths will be identical to all_runpaths except when there is a
            # rampup. In that case, test_runpaths will contain the runpaths for all
            # repetitions of each level of virtual users. 
            @test_runpaths << runpath
            
            testrun.call("Run #{runnum}", runpath)
            
            # Only sleep if requested and there is more than 1 test run
            if @testdef.sleep && @testdef.sleep.to_f > 0 && @testdef.repetitions > 1 
              run_sleeper(@testdef.sleep)
            end
            Stella::LOGGER.info('') unless @quiet # We want the newline
          end
          
          # Rampup tests produce multiple summary files which include the batch
          # number. Regular runs have just one file we set here as the default. 
          summary_name = "STATS"
        
          # It's possible for the interval to not divide evenly into the ceiling
          # If we have room between the current number of virtual users and the
          # ceiling, we'll add the difference for the final test run. 
          if (@testdef.rampup)
            final_total = @adapter.vusers + @testdef.rampup.interval
            if final_total > threshold && (threshold - @adapter.vusers) > 0
              @adapter.vusers += (threshold - @adapter.vusers)
            else
              @adapter.vusers += @testdef.rampup.interval
            end
            padded_users = @adapter.vusers.to_s.rjust(4, '0')
            summary_name << "-#{padded_users}"
          end
        
          # Read the run summaries for this batch and produce totals, averages, 
          # and standard deviations.
          @test_stats = process_test_stats(@test_runpaths)
          print_summary(test_stats) if (@testdef.repetitions > 1)
          save_summary(File.join(test_path, "#{summary_name}.#{@format}"), @test_stats)
          
          
          # Non-rampup tests only need to run through the loop once. 
          break if (!@testdef.rampup && @adapter.vusers == threshold)
        
      end

      if @testdef.rampup
        # Notice the difference between these test stats and the ones above?
        # These stats are based on the entire rampup test, across all levels
        # of virtual users.
        @rampup_test_stats = process_test_stats(@all_runpaths)
        save_summary(File.join(test_path, "STATS.#{@format}"), @rampup_test_stats)
        print_summary(test_stats) if (@testdef.repetitions > 1)
      end
    rescue Interrupt
      exit
    rescue AdapterError => ex
      Stella::LOGGER.error(ex.message)
    end
    
    def test_path_symlink
      return unless @working_directory
      File.join(@working_directory, 'latest') 
    end
    
    
    private
      
      # prepare_test
      #
      # Execute the group of testruns associated to this test. This includes
      # zero or one warmup and one or more testruns. 
      #
      # INPUT:
      # +test_path+ filesystem path to store all test data
      #
      def prepare_test(test_path)

        Stella::LOGGER.info("Writing test data to: #{test_path}\n\n") unless @quiet

        # Make sure the test storage directory is created along with the
        # latest symlink
        FileUtil.create_dir(test_path)
        if Stella.sysinfo.os == :unix
          File.unlink(test_path_symlink) if File.exists?(test_path_symlink)
          File.symlink(File.expand_path(test_path), test_path_symlink)
        end
        
        # Write the test ID to the storage directory
        # NOTE: Disabled until we resolve the issue with JRuby on OSX (won't load openssl)
        #FileUtil.write_file(test_path + "/ID.txt", @guid, true)

        # And the test run message
        FileUtil.write_file(test_path + "/MESSAGE.txt", @testdef.message, true) if @testdef.message

        @adapter.user_agent = @agents unless @agents.empty?

        # The warmup is identical to a testrun except for two things:
        # - we don't make note of the runpath
        # - there is a one second sleep after the run. 
        # Everything else is identical. 
        if @testdef.warmup

          testrun = maker_of_testruns(@testdef.warmup)

          # Generate the filesystem path to store the run data.
          # NOTE: We don't keep the warmup path in @test_runpaths because we
          # include it in the final calculation for the test. 
          runpath = File.join(test_path, "warmup")

          # Run the warmpup round
          testrun.call("Warmup", runpath)

          run_sleeper(@testdef.sleep || 1)
          
          Stella::LOGGER.info('', '') unless @quiet # We just need the newline
          
        end
        
        print_title unless @quiet

      end
        
      # maker_of_testruns
      #
      # Generator of test runs. Everything that happens during a test
      # run is defined here. We use a Proc so we can toss the functionality
      # around like something that's dirty and loves a good tossing. 
      # It's important that all output be on a single line without a
      # line terminator. Otherwise great descruction could occur.  
      def maker_of_testruns(factor)
        testrun = Proc.new do |name,runpath|
          # Make sure the test run storage directory is created
          FileUtil.create_dir(runpath)
        
          @adapter.load_factor = factor
          @adapter.working_directory = runpath
          @adapter.before
          
          Stella::LOGGER.info_printf("%8s: %10d@%-6s ", name, @adapter.requests, @adapter.vuser_rate) unless @quiet
        
          # Here we record the command arguments. This needs to be last because we modify 
          # some of the arguments above.
          FileUtil.write_file(runpath + "/COMMAND.txt", @adapter.command, true)
        
          # Execute the command, send STDOUT and STDERR to separate files. 
          command = "#{@adapter.command} 1> \"#{@adapter.stdout_path}\" 2> \"#{@adapter.stderr_path}\""
          Stella::LOGGER.info(" COMMAND: #{command}") if @verbose >= 2
          
          begin
            # Call the load tool
            # $? contains the error status
            succeeded = system(command)  
          
          # TODO: Catch interrupts for system calls. Currently it will simply and and continue with the next command
          # i.e. these don't work:
          rescue Interrupt
            exit
          rescue SystemExit
            exit
          end
          
          unless succeeded
            Stella::LOGGER.info('', '') # We used print so we need a new line for the error message.
            raise AdapterError.new(@adapter.name, @adapter.error) 
          end
          
          @adapter.after
          
          stats = @adapter.summary
      
          save_summary(@adapter.summary_path(@format), stats)
      

          if !@quiet && stats && stats.available?
            Stella::LOGGER.info_print(sprintf("%3.0f%% %9.2f/s %8.3fs ", stats.availability || 0, stats.transaction_rate || 0, stats.response_time || 0))
            Stella::LOGGER.info_print(sprintf("%8.3fMB/s %8.3fMB %8.3fs  ", stats.throughput || 0, stats.data_transferred || 0, stats.elapsed_time || 0))
            # NOTE: We don't print a line terminator here
          end
        end
      end
    
    
      # print_summary
      #
      # Called during the test after every batch of test runs. For a rampup test
      # it's also called at the end of all the runs.  
      #
      # INPUT:
      # stats:: Any object that extends Stella::Test::Base object
      def print_summary(stats)
        Stella::LOGGER.info(' ' << "-"*67) unless @quiet

        Stella::LOGGER.info_printf("%8s: %10d@%-6d %3.0f%% %9.2f/s ", "Total", stats.transactions_total || 0, stats.vusers_avg || 0, stats.availability || 0, stats.transaction_rate_avg || 0)
        Stella::LOGGER.info_printf("%8.3fs %8.3fMB/s %8.3fMB %8.3fs", stats.response_time_avg || 0, stats.throughput_avg || 0, stats.data_transferred_total || 0, stats.elapsed_time_total || 0)
        Stella::LOGGER.info('') # New line
        Stella::LOGGER.info_printf("%8s: %22s %9.2f/s %8.3fs %8.3fMB/s %10s %8.3fs", "Std Dev", '', stats.transaction_rate_sdev || 0, stats.response_time_sdev || 0, stats.throughput_sdev || 0, '', stats.elapsed_time_sdev || 0)
        Stella::LOGGER.info('') # New line
        Stella::LOGGER.info('') unless @quiet # Extra new line
      end
      
      # print_title
      #
      # Prints the column headers for the test run output. Field widths match those 
      # in print_summary and test_maker
      def print_title
        Stella::LOGGER.info(' ' << "-"*67) unless @quiet

        Stella::LOGGER.info_printf("%8s  %10s@%-5s %5s %11s", "", 'REQ', 'VU/s', 'AVAIL', 'REQ/s')
        Stella::LOGGER.info_printf("%10s %12s %10s %9s", 'RTIME', 'DATA/s', 'DATA', 'TIME')
        Stella::LOGGER.info('') # New line
        Stella::LOGGER.info('') unless @quiet # Extra new line
      end
      
      # save_summary
      #
      # Write a summary object to disk
      # 
      # INPUT:
      # filepath:: the complete path for the file (string)
      # stats:: Any object that extends Stella::Test::Base object
      def save_summary(filepath, stats)
        return unless stats
        stats.format = @format
        stats.to_file(filepath)
      end
      
      # Load SUMMARY file for each run and create a summary with
      # totals, averages, and standard deviations. 
      def process_test_stats(paths)
        return unless paths && !paths.empty?
        test_stats = Stella::Test::Stats.new(@message)
        
        paths.each do |path|
          next unless File.exists?("#{path}/SUMMARY.#{@format}")
          test_run = Stella::Test::Run::Summary.from_file("#{path}/SUMMARY.#{@format}")
          test_stats.add_run(test_run)
        end

        test_stats
      end
      
      # This is the path where all test data will be stored
      # The default is testruns/2008-12-31/test-001
      def _generate_test_path
        now = DateTime.now
        time = Time.now
        daystr = "#{now.year}-#{now.mon.to_s.rjust(2,'0')}-#{now.mday.to_s.rjust(2,'0')}"
        testpath = File.join(@working_directory, 'testruns', daystr, 'test-')
        testnum = 1.to_s.rjust(3,'0')
        testnum.succ! while(File.directory? "#{testpath}#{testnum}")
        "#{testpath}#{testnum}"
      end

      
      
  end
end

