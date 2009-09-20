require "observer"
require "tempfile"
require 'nokogiri'

module Stella
  class Client
    include Gibbler::Complex
    include Observable
    
    attr_reader :client_id
    attr_accessor :base_uri
    attr_accessor :proxy
    attr_reader :stats
    def initialize(base_uri=nil, client_id=1)
      @base_uri, @client_id = base_uri, client_id
      @cookie_file = Tempfile.new('stella-cookie')
      @stats = Stella::Stats.new("Client #{@client_id}")
      @proxy = OpenStruct.new
    end
    
    def http_client() @http_client end
      
    def execute(usecase)
      @http_client = create_http_client
      container = Container.new(usecase)
      counter = 0
      usecase.requests.each do |req|
        counter += 1
        update(:prepare_request, usecase, req, counter)
        
        uri_obj = URI.parse(req.uri)
        params = prepare_params(usecase, req.params)
        headers = prepare_headers(usecase, req.headers)
        uri = build_request_uri uri_obj, params, container
        raise NoHostDefined, uri_obj if uri.host.nil? || uri.host.empty?
        
        unique_id = [req, params, headers, counter].gibbler
        req_id = req.gibbler
        
        meth = req.http_method.to_s.downcase
        Stella.ld "#{req.http_method}: " << "#{uri_obj.to_s} " << params.inspect
        
        begin
          send_request http_client, usecase, meth, uri, req, params, headers, container
        rescue => ex
          update(:request_error, usecase, uri, req, params, ex)
          next
        end
        
        #probe_header_size(container.response)
        #probe_body_size(container.response)
        
        ret = execute_response_handler container, req
        
        Stella.lflush
        
        # TODO: consider throw/catch
        case ret.class.to_s
        when "Stella::Client::Repeat"
          Stella.ld "REPETITION: #{counter} of #{ret.times+1}"
          redo if counter <= ret.times
        when "Stella::Client::Quit"
          Stella.ld "QUIT USECASE: #{ret.message}"
          break
        end
      
        
        counter = 0 # reset
        run_sleeper(req.wait) if req.wait && !benchmark?
      end
    end
    
    def enable_benchmark_mode; @bm = true; end
    def disable_benchmark_mode; @bm = false; end
    def benchmark?; @bm == true; end
      
  private
    def send_request(http_client, usecase, meth, uri, req, params, headers, container)
      update(:send_request, usecase, uri, req, params, container)
      container.response = http_client.send(meth, uri, params, headers) # booya!
      update(:receive_response, usecase, uri, req, params, container)
    end
    
    def update(kind, *args)
      changed and notify_observers(kind, @client_id, *args)
    end
  
    def run_sleeper(wait)
      if wait.is_a?(Range)
        ms = rand(wait.last * 1000).to_f 
        ms = wait.first if ms < wait.first
      else
        ms = wait * 1000
      end
      sleep ms / 1000
    end
    
    def create_http_client
      opts = {
        :proxy       => @proxy.uri || nil, # a tautology for clarity
        :agent_name  => "Stella/#{Stella::VERSION}",
        :from        => nil
      }
      http_client = HTTPClient.new opts
      http_client.set_proxy_auth(@proxy.user, @proxy.pass) if @proxy.user
      http_client.debug_dev = STDOUT if Stella.debug? && Stella.loglev > 3
      http_client.set_cookie_store @cookie_file.to_s
      #http_client.redirect_uri_callback = ??
      http_client
    end
    
    def prepare_params(usecase, params)
      newparams = {}
      params.each_pair do |n,v|
        Stella.ld "PREPARE PARAM: #{n}"
        v = usecase.instance_eval &v if v.is_a?(Proc)
        newparams[n] = v
      end
      newparams
    end
    
    def prepare_headers(usecase, headers)
      Stella.ld "PREPARE HEADERS: #{headers}"
      headers = usecase.instance_eval &headers if headers.is_a?(Proc)
      headers
    end
    
    # Testplan URIs can be relative or absolute. Either one can
    # contain variables in the form <tt>:varname</tt>, as in:
    #
    #     http://example.com/product/:productid
    # 
    # This method creates a new URI object using the @base_uri
    # if necessary and replaces all variables with literal values.
    # If no replacement value can be found, the variable is not touched. 
    def build_request_uri(requri, params, container)
      uri = ""
      request_uri = requri.to_s
      if requri.host.nil?
        uri = base_uri.to_s
        uri.gsub! /\/$/, ''  # Don't double up on the first slash
        request_uri = '/' << request_uri unless request_uri.match(/^\//)
      end
      # We call req.uri again because we need  
      # to modify request_uri inside the loop. 
      requri.to_s.scan(/:([a-z_]+)/i) do |instances|
        instances.each do |varname|
          val = find_replacement_value(varname, params, container)
          #Stella.ld "FOUND: #{val}"
          request_uri.gsub! /:#{varname}/, val.to_s unless val.nil?
        end
      end
      uri << request_uri
      URI.parse uri
    end
    
    # Testplan URIs can contain variables in the form <tt>:varname</tt>. 
    # This method looks at the request parameters and then at the 
    # usecase's resource hash for a replacement value. 
    # If not found, returns nil. 
    def find_replacement_value(name, params, container)
      value = nil
      #Stella.ld "REPLACE: #{name}"
      #Stella.ld "PARAMS: #{params.inspect}"
      #Stella.ld "IVARS: #{container.instance_variables}"
      value = params[name.to_sym] 
      value = container.resource name.to_sym if value.nil?
      value
    end 
    
    # Find the appropriate response handler by executing the
    # HTTP response status against the configured handlers. 
    # If several match, the first one is used. 
    def execute_response_handler(container, req)
      handler = nil
      req.response.each_pair do |regex,h|
        Stella.ld "HANDLER REGEX: #{regex.to_s} (#{container.status})"
        regex = /#{regex}/ unless regex.is_a? Regexp
        handler = h and break if container.status.to_s =~ regex
      end
      ret = nil
      unless handler.nil?
        begin
          ret = container.instance_eval &handler
          update(:execute_response_handler, req, container)
        rescue => ex
          update(:error_execute_response_handler, ex, req, container)
          Stella.ld ex.message, ex.backtrace
        end
      end
      ret
    end
    
    class ResponseError < Stella::Error
      def initialize(k, m=nil)
        @kind, @msg = k, m
      end
      def message
        msg = "#{@kind}"
        msg << ": #{@msg}" unless @msg.nil?
        msg
      end
    end
    
    class Container
      attr_accessor :usecase
      attr_accessor :response
      def initialize(usecase)
        @usecase = usecase
      end
      
      def self.const_missing(const, *args)
        ResponseError.new(const)
      end
      
      def doc
        # NOTE: It's important to parse the document on every 
        # request because this container is available for the
        # entire life of a usecase. 
        case @response.header['Content-Type']
        when ['text/html']
          Nokogiri::HTML(body)
        when ['text/yaml']
          YAML.load(body)
        end
      end

      def body; @response.body.content; end
      def headers; @response.header; end
        alias_method :header, :headers
      def status; @response.status; end
      def set(n, v); usecase.resource n, v; end
      def resource(n);    usecase.resource n;    end
      def wait(t); sleep t; end
      def quit(msg=nil); Quit.new(msg); end
      def repeat(t=1); Repeat.new(t); end
    end
    
    class ResponseModifier; end
    class Repeat < ResponseModifier; 
      attr_accessor :times
      def initialize(times)
        @times = times
      end
    end
    class Quit < ResponseModifier; 
      attr_accessor :message
      def initialize(msg=nil)
        @message = msg
      end
    end
  end
end