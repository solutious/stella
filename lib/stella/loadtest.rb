module Stella
  class LoadTest
    include TestRunner

    attr_accessor :clients
    attr_accessor :repetitions
    attr_accessor :duration
    
    def run(ns)
      raise "No testplan defined" unless @testplan
      
      # TODO: one thread for each of @testplan.servers
      
      puts "Running Test: #{@name}"
      puts " -> type: #{self.class}"
      puts " -> testplan: #{@testplan.name}"
      
    end
  end
end







module Stella
  module DSL 
    module LoadTest
      include Stella::DSL::TestRunner
      
      def loadtest(name=:default, &define)
        @tests ||= {}
        @current_test = @tests[name] = Stella::LoadTest.new(name)
        define.call if define
      end
      
      def rampup(*args)
      end 
      
      def warmup(*args)
      end
          
      [:repetitions, :duration].each do |method_name|
        eval <<-RUBY, binding, '(Stella::LoadTest::DSL)', 1
        def #{method_name}(*val)
          return unless @current_test.is_a? Stella::LoadTest
          @current_test.#{method_name}=(val)
        end
        private :#{method_name}
        RUBY
      end
      
    end
  end
end