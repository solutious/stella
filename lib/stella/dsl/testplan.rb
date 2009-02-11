
# See: http://blog.jayfields.com/search/label/DSL
# See: http://expectations.rubyforge.org/

module Stella
  class TestPlan
    module DSL 
      attr_accessor :current_plan
      def testplan(name, &define)
        @plans ||= {}
        @current_plan = @plans[name] = Stella::TestPlan.new(name)
        define.call if define
      end

      def plans
        @plans 
      end
      
      def servers(*args)
        return unless @current_plan.is_a? Stella::TestPlan
        @current_plan.servers += args
      end
      
      def post(uri, &define)
        return unless @current_plan.is_a? Stella::TestPlan
        req = Stella::Data::HTTPRequest.new(uri, "POST")
        @current_plan.add_request req
        define.call if define
      end
      
      # TestPlan::Request#add_ methods
      [:header, :param, :response, :body].each do |method_name|
        eval <<-RUBY, binding, '(Stella::TestPlan::DSL)', 1
        def #{method_name}(*args, &b)
          return unless @current_plan.is_a? Stella::TestPlan
          req = @current_plan.requests.last
          req.add_#{method_name}(*args, &b)
        end
        private :#{method_name}
        RUBY
      end
      
      # TestPlan#set_ methods
      [:proxy, :auth, :base_uri].each do |method_name|
        eval <<-RUBY, binding, '(Stella::TestPlan::DSL)', 1
        def #{method_name}(*args)
          return unless @current_plan.is_a? Stella::TestPlan
          @current_plan.#{method_name}=(args)
        end
        private :#{method_name}
        RUBY
      end
      
      # = methods 
      [:protocol].each do |method_name|
        eval <<-RUBY, binding, '(Stella::TestPlan::DSL)', 1
        def #{method_name}(val)
          return unless @current_plan.is_a? Stella::TestPlan
          @current_plan.#{method_name}=(val.to_s)
        end
        private :#{method_name}
        RUBY
      end
      
    end
  end
end

  