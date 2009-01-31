

module Stella
  class CLI
    # Stella::CLI::LocalTest
    #
    # A wrapper that takes the command line input and makes it appropriate for 
    # calling an instance of Stella::LocalTest. Then it calls that instance!
    class LocalTest < Stella::CLI::Base
      
      attr_reader :testdef
      
      def initialize(adapter)
        super(adapter)
        @testdef = Stella::Test::Definition.new
        
        if (adapter == 'ab')
          @adapter = Stella::Adapter::ApacheBench.new
        elsif (adapter == 'siege')
          @adapter = Stella::Adapter::Siege.new
        elsif (adapter == 'httperf')
          @adapter = Stella::Adapter::Httperf.new
        else
          raise UnknownValue.new(adapter)
        end
        
        @driver = Stella::Command::LocalTest.new
      end
      

      def run
        process_stella_options
        
        @adapter.process_arguments(@arguments)

        @adapter.arguments = @arguments
        
        @testdef.vusers = @adapter.vusers
        @testdef.requests = @adapter.requests
        
        @driver.adapter = @adapter
        @driver.testdef = @testdef
        
        @driver.working_directory = @working_directory
        
        @driver.run
      end


      
      # process_stella_options
      # 
      # Populates @testdef with values from @stella_options
      def process_stella_options
        @testdef.repetitions = @stella_options.repetitions
        @testdef.sleep = @stella_options.sleep
        @testdef.warmup = @stella_options.warmup
        @testdef.rampup = @stella_options.rampup
        @testdef.agents = @stella_options.agents
        @testdef.message = @stella_options.message
        
        
        @driver.force = @stella_options.force
        @driver.quiet = @stella_options.quiet
        @driver.verbose = @stella_options.verbose
        @driver.format = @stella_options.format || 'yaml'
        
      end
      

      
    end
  
    
    @@commands['ab'] = Stella::CLI::LocalTest
    @@commands['siege'] = Stella::CLI::LocalTest
    @@commands['httperf'] = Stella::CLI::LocalTest
  end
end