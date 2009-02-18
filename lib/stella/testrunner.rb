# ---
# See: http://codeforpeople.com/lib/ruby/flow/flow-2.0.0/sample/a.rb
# +++

#
#
#
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
      init if respond_to? :init
    end
    
    def update(*args)
      what, *args = args
      self.send("update_#{what}", *args) if respond_to? "update_#{what}"
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
        to_run = test_name.nil? ? @tests : [@tests[test_name]]
        env = env_name.nil? ? @stella_environments.first : @stella_environments[env_name]
        to_run.each do |t|
          puts '='*60
          puts "RUNNING TEST: #{test_name}"
          puts " %11s: %s" % ['type', t.type]
          puts " %11s: %s" % ['testplan', t.testplan.name]
          puts " %11s: %s" % ['desc', t.testplan.description]
          puts " %11s: %s" % ['env', env_name]
           
          
          t.run(env, self)
        end
      end
      
      def verbose(*args)
        @current_test.verbose += args.first || 1
      end
      
    private
      
    end
  end
end
  
  
