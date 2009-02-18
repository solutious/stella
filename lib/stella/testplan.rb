
module Stella
  class TestPlan
    class ResponseHandler
      attr_accessor :action
      attr_accessor :times
      attr_accessor :wait
      def initialize(action, times=1, wait=1)
        @action = action
        @times = times
        @wait = wait
      end
    end
  end
end

module Stella

  class TestPlan
      # The name of the testplan. 
    attr_accessor :name
      # A brief description of this testplan
    attr_accessor :description
      # Used as the default protocol for the testplan. One of: http, https 
    attr_accessor :protocol
      # A Stella::TestPlan::Auth object
    attr_accessor :auth
      # An array of Stella::TestPlan::Request objects representing all "primary" requests
      # for the given test plan (an html page for example). Each primary Request object can have an array of "auxilliary"
      # requests which represent dependencies for that resource (javascript, images, callbacks, etc...).
    attr_accessor :requests
      
    def initialize(name=:anonymous)
      @name = name
      @requests = []
      @servers = []
      @protocol = "http"
    end
    
    def desc
      @description
    end
    def desc=(val)
      @description = val
    end
    
    #alias :'desc'  :'description'
    #alias :'desc=' :'description='
    
    # Append a Stella::TestPlan::Request object to +requests+.
    def add_request(req)
      raise "That is not an instance of Stella::Data::HTTPRequest" unless req.is_a? Stella::Data::HTTPRequest
      @requests << req
    end
    
      
    # Creates a Stella::TestPlan::Auth object and stores it to +@auth+
    def auth=(*args)
      type, user, pass = args.flatten
      @auth = Stella::Common::Auth.new(type, user, pass)
    end

    # A string to be parsed by URI#parsed or a URI object. The host and port are added to +@servers+ 
    # in the form "host:port". The protocol is stored in +@protocol+. NOTE: The 
    # protocol is used as a default for the test and if it's already set, this 
    # method will not try to overwrite it. 
    def base_uri=(*args)
      uri_str = args.flatten.first
      begin
        uri = URI.parse uri_str
        host_str = uri.host
        host_str << ":#{uri.port}" if uri.port
        @servers << host_str
        @protocol = uri.scheme unless @protocol
      rescue => ex
        Stella.fatal(ex)
      end
    end
    
    
  end

  
end









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

      def plans
        @plans 
      end
      
      def repeat(*args)
        raise "Repeat format does not look like a hash" unless args.first.is_a?(Hash)
        response_handler = Stella::TestPlan::ResponseHandler.new(:repeat)
        [:times, :wait].each do |att|
          response_handler.send("#{att}=", args.first[att])
        end
        
        response_handler
      end
      
      def body(*args)
        
        raise "current_plan is not a valid testplan: #{@current_plan}" unless @current_plan.is_a? Stella::TestPlan
        
        # NOTE: @current_request must be set in the calling namespace
        # before this method is called. See: make_request
        raise "current_request is not a valid request" unless @current_request.is_a? Stella::Data::HTTPRequest
        
        param, content_type, content = args if args.size == 3
        param, content = args if args.size == 2
        content = args.first if args.size == 1
        
        @current_request.add_body(content, param, content_type)
      end
      
      def response(*args, &b)
        raise "current_plan is not a valid testplan" unless @current_plan.is_a? Stella::TestPlan
        
        # NOTE: @current_request must be set in the calling namespace
        # before this method is called. See: make_request
        raise "current_request is not a valid request" unless @current_request.is_a? Stella::Data::HTTPRequest
        
        @current_request.add_response_handler(*args, &b)
      end
      private :response
      
      # TestPlan::Request#add_ methods
      [:header, :param].each do |method_name|
        eval <<-RUBY, binding, '(Stella::DSL::TestPlan)', 1
        def #{method_name}(*args, &b)
          raise "current_plan is not a valid testplan" unless @current_plan.is_a? Stella::TestPlan
          
          # NOTE: @current_request must be set in the calling namespace
          # before this method is called. See: make_request
          raise "current_request is not a valid request" unless @current_request.is_a? Stella::Data::HTTPRequest
          
          @current_request.add_#{method_name}(*args, &b)
        end
        private :#{method_name}
        RUBY
      end
      
      # TestPlan#= methods
      [:proxy, :auth, :base_uri, :desc].each do |method_name|
        eval <<-RUBY, binding, '(Stella::DSL::TestPlan)', 1
        def #{method_name}(*args)
          return unless @current_plan.is_a? Stella::TestPlan
          @current_plan.#{method_name}=(args)
        end
        private :#{method_name}
        RUBY
      end
      
      # = methods 
      [:protocol].each do |method_name|
        eval <<-RUBY, binding, '(Stella::DSL::TestPlan)', 1
        def #{method_name}(val)
          return unless @current_plan.is_a? Stella::TestPlan
          @current_plan.#{method_name}=(val.to_s)
        end
        private :#{method_name}
        RUBY
      end
      
      def post(uri, &define)
        make_request(:POST, uri, &define)
      end
        def xpost(*args); end;
        def xget(*args); end;
      
      def get(uri, &define)
        make_request(:GET, uri, &define)
      end
      
    private
      
      def make_request(method, uri, &define)
        return unless @current_plan.is_a? Stella::TestPlan
        req = Stella::Data::HTTPRequest.new(uri, method.to_s.upcase)
        @current_plan.add_request req
        index = @current_plan.requests.size
        name = :"#{index} #{req.http_method} #{req.uri}"
        req_method = Proc.new {
          # These instance variables are very important. The bring in the context
          # when the request method is called in the testrunner class. We know what 
          # the current plan is while we're executing the DSL blocks to define the 
          # request. The response block however, is called only after a require request
          # is made. We set these instance variables so that the response block will
          # know what request it's associated too.  
          instance_variable_set('@current_plan', @current_plan)
          instance_variable_set('@current_request', req)
          define.call if define
          req
        }
        metaclass.instance_eval do
          define_method(name, &req_method) 
        end

      end
      
    end
  end
end


