require "observer"
require "tempfile"
require 'httpclient'
require 'nokogiri'

module Stella
  class Client
    include Observable
    attr_reader :client_id
    attr_accessor :base_uri
    attr_accessor :proxy
    
    def initialize(base_uri=nil, client_id=1)
      @base_uri, @client_id = base_uri, client_id
      @cookie_file = Tempfile.new('stella-cookie')
    end
    
    def execute(usecase)
      http_client = generate_http_client
      container = Container.new
      usecase.requests.each do |req|
        uri = build_request_uri req, container
        raise NoHostDefined, req.uri if uri.host.nil? || uri.host.empty?
        
        meth = req.http_method.to_s.downcase
        Stella.ld "#{meth}: " << "#{req.uri.to_s} " << req.params.inspect
        
        changed and notify_observers(:send_request, meth, uri, req)
        container.response = http_client.send(meth, uri, req.params) # booya!
        changed and notify_observers(:receive_response, uri, req, container)
        
        execute_response_handler container, req
        sleep req.wait if req.wait && !benchmark?
      end
    end
    
    def enable_benchmark_mode; @bm = true; end
    def disable_benchmark_mode; @bm = false; end
    def benchmark?; @bm == true; end
      
  private
    def generate_http_client
      if @proxy
        http_client = HTTPClient.new(@proxy.uri)
        http_client.set_proxy_auth(@proxy.user, @proxy.pass) if @proxy.user
      else
        http_client = HTTPClient.new
      end
      http_client.set_cookie_store @cookie_file.to_s
      http_client
    end
    
    # Testplan URIs can be relative or absolute. Either one can
    # contain variables in the form <tt>:varname</tt>, as in:
    #
    #     http://example.com/product/:productid
    # 
    # This method creates a new URI object using the @base_uri
    # if necessary and replaces all variables with literal values.
    # If no replacement value can be found, the variable is not touched. 
    def build_request_uri(req, container)
      uri = ""
      request_uri = req.uri.to_s
      if req.uri.host.nil?
        uri = base_uri.to_s
        uri.gsub! /\/$/, ''  # Don't double up on the first slash
        request_uri = '/' << request_uri unless request_uri.match(/^\//)
      end
      # We call req.uri again because we need  
      # to modify request_uri inside the loop. 
      req.uri.to_s.scan(/:([a-z_]+)/i) do |instances|
        instances.each do |varname|
          val = find_replacement_value(varname, req.params, container)
          #Stella.ld "FOUND: #{val}"
          request_uri.gsub! /:#{varname}/, val unless val.nil?
        end
      end
      uri << request_uri
      URI.parse uri
    end
    
    # Testplan URIs can contain variables in the form <tt>:varname</tt>. 
    # This method looks at the request parameters and then at the 
    # instance variables inside the test container for a replacement
    # value. If not found, returns nil. 
    def find_replacement_value(name, params, container)
      value = nil
      #Stella.ld "REPLACE: #{name}"
      #Stella.ld "PARAMS: #{params.inspect}"
      #Stella.ld "IVARS: #{container.instance_variables}"
      value = params[name.to_sym] 
      if value.nil?
        container.instance_variables.each { |var|
          if var.to_s == "@#{name}"
            value = container.instance_variable_get("@#{name}") 
            break
          end
        }
      end
      value
    end 
    
    # Find the appropriate response handler by executing the
    # HTTP response status against the configured handlers. 
    # If several match, the first one is used. 
    def execute_response_handler(container, req)
      handlers = req.response.select do |regex,handler|
        regex = /#{regex}/ unless regex.is_a? Regexp
        Stella.ld "HANDLER REGEX: #{regex} (#{container.status})"
        container.status.to_s =~ regex
      end
      unless handlers.empty?
        begin
          changed
          container.instance_eval &handlers.values.first
          notify_observers(:execute_response_handler, req, container)
        rescue => ex
          notify_observers(:error_execute_response_handler, ex, req, container)
          Stella.ld ex.message, ex.backtrace
        end
      end
    end
    
    class Container
      attr_accessor :response
      def doc
        case @response.header['Content-Type']
        when ['text/html']
          Nokogiri::HTML(body)
        end
      end

      def body; @response.body.content; end
      def headers; @response.header; end
        alias_method :header, :headers
      def status; @response.status; end
      def set(n, v); instance_variable_set "@#{n}", v; end
      def get(n);    instance_variable_get "@#{n}";    end
    end
  end
end