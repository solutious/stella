

module Stella
  module DSL 
    module LoadTest
      attr_accessor :current_test
      
      def loadtest(name=:default, &define)
        @tests ||= {}
        @current_test = @tests[name] = Stella::LoadTest.new(name)
        define.call if define
      end
      
      def plan(testplan)
        raise "Unknown testplan, '#{testplan}'" unless @plans.has_key?(testplan)
        return unless @current_test
        @current_test.testplan = @plans[testplan]
      end
      
      
      def run(test=nil)
        to_run = (test.nil?) ? @tests : [@tests[test]]
        to_run.each do |t|
          t.run
        end
      end
      
      [:users, :repetitions, :duration].each do |method_name|
        eval <<-RUBY, binding, '(Stella::LoadTest::DSL)', 1
        def #{method_name}(val)
          return unless @current_test.is_a? Stella::LoadTest
          @current_test.#{method_name}=(val)
        end
        private :#{method_name}
        RUBY
      end
      
    end
  end
end