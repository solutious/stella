
module Stella
  class TestPlan
    class Auth
      attr_accessor :type
      attr_accessor :user
      attr_accessor :pass
      def initialize(type, user, pass=nil)
        @uri = type
        @user = user
        @pass = pass if pass
      end
    end
    class Proxy 
      attr_accessor :uri
      attr_accessor :user
      attr_accessor :pass
      def initialize(uri, user=nil, pass=nil)
        @uri = uri
        @user = user if user
        @pass = pass if pass
      end
    end
    class Server
      attr_accessor :host
      attr_accessor :port
      def initialize(*args)
        raise "You must at least a hostname or IP address" if args.empty?
        if args.first.is_a? String
          @host, @port = args.first.split(":") 
        else  
          @host, @port = args.flatten
        end
        
        @port = @port.to_i if @port
      end
      def to_s
        str = "#{@host}"
        str << ":#{@port}" if @port
        str
      end
    end
  end
end

module Stella

  class TestPlan
      # The name of the testplan. 
    attr_accessor :name
      # An array of `::Server objects to be use during the test.
      #     tp.servers << "stellaaahhhh.com:80"
    attr_accessor :servers
      # Used as the default protocol for the testplan. One of: http, https 
    attr_accessor :protocol
      # A Stella::TestPlan::Auth object
    attr_accessor :auth
      # A Stella::TestPlan::Proxy object containing the proxy to be used for the test.
    attr_accessor :proxy
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
    
    # Append a Stella::TestPlan::Request object to +requests+.
    def add_request(req)
      raise "That is not an instance of Stella::Data::HTTPRequest" unless req.is_a? Stella::Data::HTTPRequest
      @requests << req
    end
    
    def add_servers(*args)
      return if args.empty?
      args.each do |server|
        @servers << Stella::TestPlan::Server.new(server)
      end
    end
      
    # Creates a Stella::TestPlan::Auth object and stores it to +@auth+
    def auth=(*args)
      type, user, pass = args.flatten
      @auth = Stella::TestPlan::Auth.new(type, user, pass)
    end
    
    # Creates a Stella::TestPlan::Proxy object and stores it to +@proxy+
    def proxy=(*args)
      uri, user, pass = args.flatten
      @proxy = Stella::TestPlan::Proxy.new(uri, user, pass)
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
      
      def servers(*args)
        return unless @current_plan.is_a? Stella::TestPlan
        args.each do |server|
          @current_plan.add_servers server
        end
      end
      

      
      # TestPlan::Request#add_ methods
      [:header, :param, :response, :body].each do |method_name|
        eval <<-RUBY, binding, '(Stella::TestPlan::DSL)', 1
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
      
      def post(uri, &define)
        make_request(:POST, uri, &define)
      end
      
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


