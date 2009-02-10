
require 'uri'
require 'stella/testplan/helpers'
require 'stella/testplan/dsl'

module Stella
  
  # 
  # 
  # 
  class TestPlan
      # The name of the testplan. 
    attr_accessor :name
      # A URI object containing the base URI for the test.
    attr_accessor :base_uri
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
    end
    
    # Append a Stella::Testplan::Request object to +requests+.
    def add_request(req)
      raise "That is not an instance of Stella::TestPlan::Request" unless req.is_a? Stella::TestPlan::Request
      (@requests ||= []) << req
    end
      
    # Creates a Stella::Testplan::Auth object and stores it to +@auth+
    def set_auth(type, user, pass=nil)
      @auth = Stella::TestPlan::Auth.new(type, user, pass)
    end
    
    # Creates a Stella::Testplan::Proxy object and stores it to +@proxy+
    def set_proxy(uri, user, pass=nil)
      @proxy = Stella::TestPlan::Proxy.new(uri, user, pass)
    end
    
    # Creates a URI object and stores it to +@base_uri+
    def set_base_uri(uri)
      begin
        @base_uri = URI.parse uri
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