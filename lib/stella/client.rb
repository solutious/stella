require "observer"
require "nokogiri"
require 'pp'

Stella::Utils.require_vendor "httpclient", '2.1.5.2'

module Stella
  class Client
    MAX_REDIRECTS = 5.freeze unless defined?(MAX_REDIRECTS)
    
    require 'stella/client/container'
    
    include Gibbler::Complex
    include Observable
    
    attr_reader :index
    attr_accessor :base_uri
    attr_accessor :proxy
    
    gibbler :opts, :index, :base_uri, :proxy, :nowait
    
    def initialize(base_uri=nil, index=1, opts={})
      opts = {
        :'no-templates' => false
      }.merge! opts
      @opts = opts
      @base_uri, @index = base_uri, index
      #@cookie_file = File.new("cookies-#{index}", 'w')
      @proxy = OpenStruct.new
    end
    def execute(usecase, &stat_collector)
#      Gibbler.enable_debug
      # We need to make sure the digest cache has a value
      self.digest if self.digest_cache.nil?
      Gibbler.disable_debug
      http_client = create_http_client
      stats = {}
      container = Container.new(self.digest_cache, usecase)
      counter = 0
      usecase.requests.each do |req|
        counter += 1
        
        container.reset_temp_vars
        
        stats ||= Benelux::Stats.new
        update(:prepare_request, usecase, req, counter)
        
        begin
          # This is for the values that were "set"
          # in the part before the response body.
          prepare_resources(container, req.resources)
          
          params = prepare_params(container, req.params)
          headers = prepare_headers(container, req.headers)
        
          container.params, container.headers = params, headers
          
          uri = build_request_uri req.uri, params, container
          
          if http_auth = req.http_auth || usecase.http_auth
            # TODO: The first arg is domain and can include a URI path. 
            #       Are there cases where this is important?
            domain = http_auth.domain
            domain ||= '%s://%s:%d%s' % [uri.scheme, uri.host, uri.port, req.uri] 
            domain = container.instance_eval &domain if Proc === domain
            Stella.ld "DOMAIN " << domain
            user, pass = http_auth.user, http_auth.pass
            user = container.instance_eval &user if Proc === user
            pass = container.instance_eval &pass if Proc === pass
            update(:authenticate, usecase, req, domain, user, pass)
            http_client.set_auth(domain, user, pass)
          end
          
          if tout = req.timeout || usecase.timeout
            http_client.receive_timeout = tout
          end
          Stella.ld "TIMEOUT " << http_client.receive_timeout.to_s
          
          raise NoHostDefined, req.uri if uri.host.nil? || uri.host.empty?
          stella_id = [Time.now.to_f, self.digest_cache, req.digest_cache, params, headers, counter].digest
        
          Benelux.add_thread_tags :request => req.digest_cache
          Benelux.add_thread_tags :retry => counter
          Benelux.add_thread_tags :stella_id => stella_id
          
          container.unique_id = stella_id
          
          params['__stella'] = container.unique_id unless @opts[:'no-param']
          headers['X-Stella-ID'] = container.unique_id unless @opts[:'no-header']
          
          meth = req.http_method.to_s.downcase
          Stella.ld "#{req.http_method}: " << "#{req.uri} " << params.inspect
        
          ret, asset_duration = nil, 0
        rescue => ex
          update(:request_unhandled_exception, usecase, uri, req, params, ex)
          update(:usecase_error, ex.message, uri, container)
          Benelux.remove_thread_tags :status, :retry, :request, :stella_id
          break
        end
        
        begin
          send_request http_client, usecase, meth, uri, req, params, headers, container, counter
          update(:receive_response, usecase, uri, req, params, headers, counter, container)
          Benelux.add_thread_tags :status => container.status
          res = container.response
          [
            [:request_header_size, res.request.header.dump.size],
            [:request_content_size, res.request.body.content.size],
            [:response_headers_size, res.header.dump.size],
            [:response_content_size, res.body.content.size]
          ].each do |att|
            Benelux.thread_timeline.add_count att[0], att[1]
          end
          ret = execute_response_handler container, req
          
          asset_start = Time.now
          container.assets.each do |uri|
            Benelux.add_thread_tags :asset => uri
            a = http_client.get uri
            Stella.stdout.info3 "   FETCH ASSET: #{uri} #{a.status}"
            Benelux.remove_thread_tags :asset
          end
          asset_duration = Time.now - asset_start
        rescue HTTPClient::ConnectTimeoutError, HTTPClient::SendTimeoutError,
               HTTPClient::ReceiveTimeoutError => ex
          update(:request_timeout, usecase, uri, req, params, headers, counter, container)
          Benelux.remove_thread_tags :status, :retry, :request, :stella_id
          next
        rescue => ex
          update(:request_unhandled_exception, usecase, uri, req, params, ex)
          Benelux.remove_thread_tags :status, :retry, :request, :stella_id
          next
        end
        
        run_sleeper(req.wait, asset_duration) if req.wait != 0 && !nowait?
        
        # TODO: consider throw/catch
        case ret.class.to_s
        when "Stella::Client::Repeat"
          update(:request_repeat, counter, ret.times+1, uri, container)
          Benelux.remove_thread_tags :status
          redo if counter <= ret.times
        when "Stella::Client::Follow"
          ret.uri ||= container.header['Location'].first
          if counter > MAX_REDIRECTS
            update(:max_redirects, counter-1, ret, uri, container)
            break
          else
            req = ret.generate_request(req)
            update(:follow_redirect, ret, uri, container)
            Benelux.remove_thread_tags :status, :request
            redo
          end
        when "Stella::Client::Quit"
          update(:usecase_quit, ret.message, uri, container)
          Benelux.remove_thread_tags :status
          break
        when "Stella::Client::Fail"  
          update(:request_fail, ret.message, uri, container)
        when "Stella::Client::Error"  
          update(:request_error, ret.message, uri, container)
        end
        
        Benelux.remove_thread_tags :status
        
        counter = 0 # reset
      end
      Benelux.remove_thread_tags :retry, :request, :stella_id
      stats
    end
    
    def enable_nowait_mode; @nowait = true; end
    def disable_nowait_mode; @nowait = false; end
    def nowait?; @nowait == true; end
      
  private
    # We use a method so we can time it with Benelux
    def send_request(http_client, usecase, meth, uri, req, params, headers, container, counter)
      if meth == "delete"
        args = [meth, uri, headers]
      else
        args = [meth, uri, params, headers]
      end
      container.response = http_client.send(*args) # booya!
    end
    
    def update(kind, *args)
      changed and notify_observers(kind, self.digest_cache, *args)
    end
  
    def run_sleeper(wait, already_waited=0)
      # The time it took to download the assets can
      # be removed from the specified wait time.
      if wait.is_a?(::Range)
        ms = rand(wait.last * 1000).to_f 
        ms = wait.first if ms < wait.first
      else
        ms = wait * 1000
      end
      sec = ms / 1000
      Stella.ld "WAIT ADJUSTED FROM %.1f TO: %.1f" % [sec, (sec - already_waited)]
      sleep (sec - already_waited) if (sec - already_waited) > 0
    end
    
    def create_http_client
      opts = {
        :proxy       => @proxy.uri || nil, # a tautology for clarity
        :agent_name  => "Stella/#{Stella::VERSION}",
        :from        => nil
      }
      http_client = HTTPClient.new opts
      http_client.set_proxy_auth(@proxy.user, @proxy.pass) if @proxy.user
      http_client.debug_dev = STDOUT if Stella.debug? 
      http_client.protocol_version = "HTTP/1.1"
      http_client.ssl_config.verify_mode = ::OpenSSL::SSL::VERIFY_NONE
      http_client
    end
    
    def prepare_resources(container, resources)
      h = prepare_runtime_hash container, resources
      # p [container.client_id.shorter, h]
      container.resources.merge! h
    end
    
    # Process resource values from the request object
    def prepare_runtime_hash(container, hashobj, &extra)
      newh = {}
      #Stella.ld "PREPARE HEADERS: #{headers}"
      hashobj.each_pair do |n,v|
        v = container.instance_eval &v if v.is_a?(Proc)
        unless @opts[:'no-templates']
          v = container.parse_template v if String === v
        end
        v = extra.call(v) unless extra.nil?
        newh[n] = v
      end
      newh
    end
    alias_method :prepare_headers, :prepare_runtime_hash
    alias_method :prepare_params, :prepare_runtime_hash
    
    # Testplan URIs can be relative or absolute. Either one can
    # contain variables in the form <tt>:varname</tt>, as in:
    #
    #     http://example.com/product/:productid
    # 
    # This method creates a new URI object using the @base_uri
    # if necessary and replaces all variables with literal values.
    # If no replacement value can be found, the variable will remain. 
    def build_request_uri(uri, params, container)
      raise "Request given with no URI" if uri.nil?
      newuri = uri.clone  # don't modify uri template
      # We call uri.clone b/c we modify uri. 
      uri.scan(/([:\$])([a-z_]+)/i) do |inst|
        val = find_replacement_value(inst[1], params, container, base_uri)
        Stella.ld "FOUND VAR: #{inst[0]}#{inst[1]} (value: #{val})"
        re = Regexp.new "\\#{inst[0]}#{inst[1]}"
        newuri.gsub! re, val.to_s unless val.nil?
      end

      uri = URI.parse(newuri)
      
      if uri.host.nil? && base_uri.nil?
        Stella.abort!
        raise NoHostDefined, uri
      end
      
      uri.scheme = base_uri.scheme if uri.scheme.nil?
      uri.host = base_uri.host if uri.host.nil?
      uri.port = base_uri.port if uri.port.nil?
      
      # Support for specifying default path prefix:
      # $ stella verify -p plan.rb http://localhost/basicauth
      if base_uri.path
        if uri.path.nil? || uri.path.empty?
          uri.path = base_uri.path
        else
          a = base_uri.path.gsub(/\/$/, '')
          b = uri.path.gsub(/^\//, '')
          uri.path = [a,b].join('/')
        end
      end
      
      uri
    end
    
    # Testplan URIs can contain variables in the form <tt>:varname</tt>. 
    # This method looks at the request parameters and then at the 
    # usecase's resource hash for a replacement value. 
    # If not found, returns nil. 
    def find_replacement_value(name, params, container, base_uri)
      value = nil
      #Stella.ld "REPLACE: #{name}"
      #Stella.ld "PARAMS: #{params.inspect}"
      #Stella.ld "IVARS: #{container.instance_variables}"
      if name.to_sym == :HOSTNAME && !base_uri.nil?
        value = base_uri.host 
      elsif params.has_key?(name.to_sym)
        value = params.delete name.to_sym
      elsif container.resource?( name)
        value = container.resource name
      elsif Stella::Testplan.global?(name)
        Stella::Testplan.global(name)
      end
      value
    end 
    
    # Find the appropriate response handler by executing the
    # HTTP response status against the configured handlers. 
    # If several match, the first one is returned.
    def find_response_handler(container, req)
      handler = nil
      req.response.each_pair do |regex,h|
        Stella.ld "HANDLER REGEX: #{regex.to_s} (#{container.status})"
        regex = /#{regex}/ unless regex.is_a? Regexp
        handler = h and break if container.status.to_s =~ regex
      end
      handler
    end
    
    
    def execute_response_handler(container, req)
      ret = nil
      handler = find_response_handler container, req
      if handler.nil?
        if container.status >= 400
          update(:request_fail, "No handler", req.uri, container) 
        end
        return
      end
      begin
        ret = container.instance_eval &handler
        update(:execute_response_handler, req, container)
      rescue => ex
        update(:error_execute_response_handler, ex, req, container)
        Stella.ld ex.message, ex.backtrace
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


class Stella::Client
  
  class ResponseModifier
    attr_accessor :obj
    def initialize(obj=nil)
      @obj = obj
    end 
    alias_method :message, :obj
    alias_method :message=, :obj=
  end
  class Repeat < ResponseModifier; 
    alias_method :times, :obj
    alias_method :times=, :obj=
  end
  #
  # Automatically follow a Location header or you 
  # can optionally specify the URI to load. 
  # 
  #     get '/' do
  #       response 302 do
  #         follow do 
  #           header :'X-SOME-HEADER' => 'somevalue'
  #         end
  #       end
  #     end
  #
  # The block is optional and accepts the same syntax as regular requests.
  #
  class Follow < ResponseModifier; 
    alias_method :uri, :obj
    alias_method :uri=, :obj=
    attr_reader :definition
    def initialize(obj=nil,&definition)
      @obj, @definition = obj, definition
    end
    def generate_request(req)
      n = Stella::Data::HTTP::Request.new :GET, self.uri, req.http_version, &definition
      n.description = "#{req.description || 'Request'} (autofollow)"
      n.http_auth = req.http_auth
      n.response_handler = req.response_handler
      n.autofollow!
      n.freeze
      n
    end
  end
  class Quit < ResponseModifier; end
  class Fail < Quit; end
  class Error < Quit; end
  
end
