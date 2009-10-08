require "observer"
require "nokogiri"

Stella::Utils.require_vendor "httpclient", '2.1.5.2'

module Stella
  class Client
    require 'stella/client/modifiers'
    require 'stella/client/container'
    
    include Gibbler::Complex
    include Observable
    
    attr_reader :client_id
    attr_accessor :base_uri
    attr_accessor :proxy
    
    def initialize(base_uri=nil, client_id=1)
      @base_uri, @client_id = base_uri, client_id
      #@cookie_file = File.new("cookies-#{client_id}", 'w')
      @proxy = OpenStruct.new
    end
    def execute(usecase, &stat_collector)
      # We need to make sure the gibbler cache has a value
      self.gibbler if self.digest_cache.nil?
      
      http_client = create_http_client
      stats = {}
      container = Container.new(usecase)
      counter = 0
      usecase.requests.each do |req|
        counter += 1
        
        stats ||= Benelux::Stats.new
        update(:prepare_request, usecase, req, counter)
        uri_obj = URI.parse(req.uri)
        params = prepare_params(container, req.params)
        headers = prepare_headers(container, req.headers)
        uri = build_request_uri uri_obj, params, container
        raise NoHostDefined, uri_obj if uri.host.nil? || uri.host.empty?
        stella_id = [Time.now, self.digest_cache, req.digest_cache, params, headers, counter].gibbler
        
        Benelux.add_thread_tags :request => req.digest_cache
        Benelux.add_thread_tags :retry => counter
        Benelux.add_thread_tags :stella_id => stella_id
        
        params['__stella'] = stella_id.short
        headers['X-Stella-ID'] = stella_id.short
        
        meth = req.http_method.to_s.downcase
        Stella.ld "#{req.http_method}: " << "#{uri_obj.to_s} " << params.inspect

        begin
          send_request http_client, usecase, meth, uri, req, params, headers, container, counter
          
          Benelux.add_thread_tags :status => container.status
          Benelux.thread_timeline.add_count :request_header_size, container.response.request.header.dump.size
          Benelux.thread_timeline.add_count :request_content_size, container.response.request.body.content.size
          Benelux.thread_timeline.add_count :response_headers_size, container.response.header.dump.size
          Benelux.thread_timeline.add_count :response_content_size, container.response.body.content.size
          ret = execute_response_handler container, req
          Benelux.remove_thread_tags :status
           
        rescue => ex
          Benelux.thread_timeline.add_count :failed, 1
          update(:request_error, usecase, uri, req, params, ex)
          next
        end
        
        Stella.lflush
        
        run_sleeper(req.wait) if req.wait && !nowait?
        
        # TODO: consider throw/catch
        case ret.class.to_s
        when "Stella::Client::Repeat"
          update(:repeat_request, counter, ret.times+1)
          redo if counter <= ret.times
        when "Stella::Client::Quit"
          update(:quit_usecase, ret.message)
          break
        end
      
        counter = 0 # reset
      end
      Benelux.remove_thread_tags :retry, :request, :stella_id
      stats
    end
    
    def enable_nowait_mode; @nowait = true; end
    def disable_nowait_mode; @nowait = false; end
    def nowait?; @nowait == true; end
      
  private
    def send_request(http_client, usecase, meth, uri, req, params, headers, container, counter)
      container.response = http_client.send(meth, uri, params, headers) # booya!
      update(:receive_response, usecase, uri, req, counter, container)
    end
    
    def update(kind, *args)
      changed and notify_observers(kind, self.digest_cache, *args)
    end
  
    def run_sleeper(wait)
      if wait.is_a?(::Range)
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
      #http_client.set_cookie_store @cookie_file.path
      http_client.protocol_version = "HTTP/1.1"
      http_client
    end
    
    def prepare_params(container, params)
      newparams = {}
      params.each_pair do |n,v|
        Stella.ld "PREPARE PARAM: #{n}"
        v = container.instance_eval &v if v.is_a?(Proc)
        newparams[n] = v
      end
      newparams
    end
    
    def prepare_headers(container, headers)
      Stella.ld "PREPARE HEADERS: #{headers}"
      headers = container.instance_eval &headers if headers.is_a?(Proc)
      headers
    end
    
    # Testplan URIs can be relative or absolute. Either one can
    # contain variables in the form <tt>:varname</tt>, as in:
    #
    #     http://example.com/product/:productid
    # 
    # This method creates a new URI object using the @base_uri
    # if necessary and replaces all variables with literal values.
    # If no replacement value can be found, the variable will remain. 
    def build_request_uri(uri, params, container)
      uri = URI::HTTP.build({:path => uri}) unless uri.is_a?(URI::Generic)
      
      if uri.host.nil? && base_uri.nil?
        Stella.abort!
        raise NoHostDefined, uri
      end
      
      uri.scheme = base_uri.scheme if uri.scheme.nil?
      uri.host = base_uri.host if uri.host.nil?
      uri.port = base_uri.port if uri.port.nil?
      uri.path ||= ''
      uri.path.gsub! /\/$/, ''  # Don't double up on the first slash
      # We call req.uri again because we need  
      # to modify request_uri inside the loop. 
      uri.path.clone.scan(/:([a-z_]+)/i) do |instances|
        instances.each do |varname|
          val = find_replacement_value(varname, params, container)
          #Stella.ld "FOUND: #{val}"
          uri.path.gsub! /:#{varname}/, val.to_s unless val.nil?
        end
      end
      uri
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
    
  end
end