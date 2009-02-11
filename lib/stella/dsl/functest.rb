

module Stella
  class FunctionalTest
    module DSL 
      attr_accessor :current_test
      
      def functest(name=:default, &define)
        @tests ||= {}
        @current_test = @tests[name] = Stella::FunctionalTest.new(name)
        define.call if define
      end
      
      def plan(testplan)
        raise "Unknown testplan, '#{testplan}'" unless @plans.has_key?(testplan)
        return unless @current_test
        @current_test.testplan = @plans[testplan]
      end
      
    end
  end
end