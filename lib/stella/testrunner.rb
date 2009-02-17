

module Stella
  module TestRunner
    attr_accessor :name
      # Name or instance of the testplan to execute
    attr_accessor :testplan
      # Determines the amount of output. Default: 0
    attr_accessor :verbose
    
    def initialize(name=:default)
      @name = name
      @verbose = 0
    end
    
    
  end
  module DSL
    module TestRunner
      attr_accessor :current_test
      
      def plan(testplan)
        raise "Unknown testplan, '#{testplan}'" unless @plans.has_key?(testplan)
        return unless @current_test
        @current_test.testplan = @plans[testplan]
      end
      
      def run(env=nil, test=nil)
        puts "Run #{test} in #{env}"
        #to_run = (test.nil?) ? @tests : [@tests[test]]
        #to_run.each do |t|
        #  t.run(self)
        #end
      end
      
      def verbose(*args)
        @current_test.verbose += args.first || 1
      end
    end
  end
end
  
  
