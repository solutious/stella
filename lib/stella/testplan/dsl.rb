
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
      
      def header(*args)
        return unless @current_plan.is_a? Stella::TestPlan
        return if args.empty?
        name, value = (args[0].is_a? Hash) ? args[0].to_a.flatten : args
        req = @current_plan.requests.last
        req.add_header(name, value)
      end
      
      def param(*args)
        return unless @current_plan.is_a? Stella::TestPlan
        return if args.empty?
        name, value = (args[0].is_a? Hash) ? args[0].to_a.flatten : args
        req = @current_plan.requests.last
        req.add_param(name, value)
      end
      
      def params(p)
        return unless @current_plan.is_a? Stella::TestPlan
        # TODO: implement passing hashes
      end
      
      def file(path, form_param=nil, content_type=nil)
        return unless @current_plan.is_a? Stella::TestPlan
        req = @current_plan.requests.last
        req.add_body(path, form_param, content_type)
      end
      
      def post(uri, &define)
        return unless @current_plan.is_a? Stella::TestPlan
        req = Stella::TestPlan::Request.new(uri, "POST")
        @current_plan.add_request req
        define.call if define
      end
      
      def response(code=200, &b)
        return unless @current_plan.is_a? Stella::TestPlan
        req = @current_plan.requests.last
        req.add_response(code, &b)
      end
      
      [:base_uri, :auth, :proxy].each do |method_name|
        eval <<-RUBY, binding, '(Stella::TestPlan::DSL)', 1
        def #{method_name}(*args, &b)
          return unless @current_plan.is_a? Stella::TestPlan
          @current_plan.set_#{method_name}(*args)
        end
        private :#{method_name}
        RUBY
      end
           
    end
  end
end

  