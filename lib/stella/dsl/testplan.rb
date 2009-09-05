

module Stella
  module DSL
    module TestPlan 
      attr_accessor :current_plan
      attr_accessor :current_request

      def testplan(name, &define)
        @plans ||= {}
        @current_plan = @plans[name] = Stella::TestPlan.new(name)
        define.call if define
      end
      
      
    end
  end
end
