
require 'httpclient'

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
    class Request
      class Body
        attr_accessor :path
        attr_accessor :content_type
        attr_accessor :form_param
        attr_writer :content
        
        def content
          @content if @content
          raise "No content defined" unless @path && File.exists?(@path)
          File.read @path
        end
      end
      
      attr_accessor :method
      attr_accessor :http_version
      attr_accessor :headers
      attr_accessor :body
      attr_accessor :uri
      attr_accessor :params
      attr_accessor :requests
        # A hash containing blocks to be executed depending on the HTTP response status.
        # The hash keys are numeric HTTP Status Codes. 
        #
        #     200 => { ... }
        #     304 => { ... }
        #     500 => { ... }
        #
      attr_accessor :response
      
      def initialize (uri, method="GET")
        @uri = uri
        @method = method
        @headers = {}
        @params = {}
        @response = {}
      end
      def add_header(name, value)
        @headers[name.to_s] ||= []
        @headers[name.to_s] << value
      end
      def add_param(name, value)
        @params[name.to_s] ||= []
        @params[name.to_s] << value
      end
      
      def add_response(code=200, &b)
        @response[code] = b
      end
      def add_body(path, form_param=nil, content_type=nil)
        @body = Body.new
        @body.path = path
        @body.form_param = form_param
        @body.content_type = content_type
      end
    end
  end
end