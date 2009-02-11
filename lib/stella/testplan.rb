
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
  end
end

module Stella

  class TestPlan
      # The name of the testplan. 
    attr_accessor :name
      # An array of hostnames (with optional port number) to be use during the test.
      #     tp.servers << "stellaaahhhh.com:80"
    attr_accessor :servers
      # Used as the default protocol for the testplan. One of: http, https 
    attr_accessor :protocol
      # A Stella::Testplan::Auth object
    attr_accessor :auth
      # A Stella::Testplan::Proxy object containing the proxy to be used for the test.
    attr_accessor :proxy
      # An array of Stella::Testplan::Request objects representing all "primary" requests
      # for the given test plan (an html page for example). Each primary Request object can have an array of "auxilliary"
      # requests which represent dependencies for that resource (javascript, images, callbacks, etc...).
    attr_accessor :requests
      
    def initialize(name=:anonymous)
      @name = name
      @requests = []
      @servers = []
      @protocol = "http"
    end
    
    # Append a Stella::Testplan::Request object to +requests+.
    def add_request(req)
      raise "That is not an instance of Stella::Data::HTTPRequest" unless req.is_a? Stella::Data::HTTPRequest
      @requests << req
    end
    
    def add_servers(*args)
      return if args.empty?
      @servers += args
    end
      
    # Creates a Stella::Testplan::Auth object and stores it to +@auth+
    def auth=(*args)
      type, user, pass = args.flatten
      puts user
      @auth = Stella::TestPlan::Auth.new(type, user, pass)
    end
    
    # Creates a Stella::Testplan::Proxy object and stores it to +@proxy+
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

class Object
  # The hidden singleton lurks behind everyone
     def metaclass; class << self; self; end; end
     def meta_eval &blk; metaclass.instance_eval &blk; end

     # Adds methods to a metaclass
     def meta_def name, &blk
       meta_eval { define_method name, &blk }
     end

     # Defines an instance method within a class
     def class_def name, &blk
       class_eval { define_method name, &blk }
     end
  
  end