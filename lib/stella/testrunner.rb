

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
      
      def run(env_name=nil, test_name=nil)
        puts "Run #{test_name} in #{env_name}"
        to_run = test_name.nil? ? @tests : [@tests[test_name]]
        env = env_name.nil? ? @stella_environments.first : @stella_environments[env_name]
        to_run.each do |t|
          t.run(self, env)
        end
      end
      
      def verbose(*args)
        @current_test.verbose += args.first || 1
      end
    end
  end
end
  
  
