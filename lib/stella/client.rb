
require 'base64'
require 'addressable/uri'

Stella::Utils.require_vendor "httpclient", '2.1.5.2'

require 'pp'

class Stella
  
  class Client
    unless defined?(SSL_CERT_PATH)
      SSL_CERT_PATH = File.join(STELLA_LIB_HOME, '..', 'certs', 'stella-master.crt').freeze
    end
    
    include Gibbler::Complex
    include HTTPClient::Timeout
    
    attr_reader :index
    attr_accessor :base_uri
    attr_accessor :proxy
    attr_accessor :created 
    attr_reader :clientid
    
    gibbler :index, :opts, :base_uri, :proxy, :created
    
    @@client_index = 0
    
    # Options:
    # 
    # * :timeout (Integer) => 30
    # * :ssl_verify_mode (Class) => nil (possible values: OpenSSL::SSL::VERIFY_NONE)
    #
    def initialize(opts={})
      @index = @@client_index += 1
      @created = Stella.now
      @opts = opts
      @opts[:timeout] ||= 30
      @base_uri, @index = opts[:base_uri] || opts['base_uri'], index
      @proxy = OpenStruct.new
      @done = false
      @session = Session.new @base_uri
      @redirect_count = 0
      @clientid = [@session.object_id, created, index, opts].digest
    end
    
    def exception 
      @session.exception
    end
    
    def execute usecase, &each_request
      @session.http_client = create_http_client
      tt = Benelux.current_track.timeline
      usecase.requests.each_with_index do |rt,idx|
        begin 
          debug "request start (session: #{@session.object_id})"
          @session.prepare_request usecase, rt 
          
          debug "#{@session.http_method} #{@session.uri} (#{rt.id.short})"
          debug " #{@session.params.inspect}" unless @session.params.empty?
          debug " #{@session.headers.inspect}" unless @session.headers.empty?
          
          stella_id = [clientid, rt.id, @session.uri.to_s, @session.params, @session.headers, idx].digest
          
          Benelux.current_track.add_tags :request   => rt.id
          Benelux.current_track.add_tags :stella_id => stella_id
          
          ## Useful for testing larger large request header
          ## 50.times do |idx|
          ##   headers["X-header-#{idx}"] = (1000 << 1000).to_s
          ## end
          
          # Mis-behaving HTTP servers will fail w/o an Accept header
          @session.headers["Accept"] ||= '*/*'
          
          # if hard_timeout is nil this will do nothing
          timeout(@opts[:hard_timeout], TimeoutError) do
            @session.generate_request stella_id
          end
          res = @session.res
          
          each_request.call(@session) unless each_request.nil?
          
          # Needs to happen before handle response incase it raises an exception
          log = Stella::Log::HTTP.new Stella.now,  
                   @session.http_method, @session.uri, @session.params, res.request.header.dump, 
                   res.request.body.content, res.status, res.header.dump, res.body.content
          
          tt.add_count :requests, 1, :kind => :http
          
          run_sleeper @opts[:wait]
          
          if @session.response_handler?
            @session.handle_response
          elsif res.status >= 400
            raise Stella::HTTPError.new(res.status)
          elsif rt.follow && @session.redirect?
            raise ForcedRedirect, @session.location
          end

          tt.add_message log, :status => res.status, :kind => :http_log, :state => :nominal
          
          @redirect_count = 0
          
        rescue RepeatRequest => ex
          debug " REPEAT REQUEST: #{@session.location}"
          retry
          
        rescue ForcedRedirect => ex  
          # TODO: warn when redirecting from https to http
          debug " FOUND REDIRECT: #{@session.location}"
          if @redirect_count < 10
            @redirect_count += 1
            @session.clear_previous_request
            @session.redirect_uri = ex.location
            retry
          end
        
        rescue Errno::ETIMEDOUT, SocketError, 
               HTTPClient::ConnectTimeoutError, 
               HTTPClient::SendTimeoutError,
               HTTPClient::ReceiveTimeoutError,
               TimeoutError,
               Errno::ECONNRESET => ex
          debug "[#{ex.class}] #{ex.message}"
          log = Stella::Log::HTTP.new Stella.now, @session.http_method, @session.uri, @session.params
          if @session.res 
            log.request_headers = @session.res.request.header.dump if @session.res.request 
            log.request_body = @session.res.request.body.content if @session.res.request 
            log.response_status = @session.res.status
            log.response_headers = @session.res.header.dump if @session.res.content
            log.response_body = @session.res.body.content if @session.res.body
          end
          log.msg = "#{ex.class} (#{@session.http_client.receive_timeout})"
          tt.add_message log, :kind => :http_log, :state => :timeout
          Benelux.current_track.remove_tags :status, :request, :stella_id
          next
          
        rescue StellaError, StellaBehavior => ex
          debug "[#{ex.class}] #{ex.message}"
          log = Stella::Log::HTTP.new Stella.now, @session.http_method, @session.uri, @session.params
          if @session.res 
            log.request_headers = @session.res.request.header.dump if @session.res.request 
            log.request_body = @session.res.request.body.content if @session.res.request 
            log.response_status = @session.res.status
            log.response_headers = @session.res.header.dump if @session.res.content
            log.response_body = @session.res.body.content if @session.res.body
          end
          log.msg = ex.message
          tt.add_message log, :status => log.response_status, :kind => :http_log, :state => :exception
          Benelux.current_track.remove_tags :status, :request, :stella_id
          @session.exception = ex
          break
        
        rescue Errno::ECONNREFUSED => ex
          debug "[#{ex.class}] #{ex.message}"
          log = Stella::Log::HTTP.new Stella.now, @session.http_method, @session.uri, @session.params
          log.msg = "Connection refused"
          tt.add_message log, :status => log.response_status, :kind => :http_log, :state => :exception
          Benelux.current_track.remove_tags :status, :request, :stella_id
          break
        
        rescue OpenSSL::SSL::SSLError => ex
          debug "[#{ex.class}] #{ex.message}"
          log = Stella::Log::HTTP.new Stella.now, @session.http_method, @session.uri, @session.params
          log.msg = ex.message
          tt.add_message log, :status => log.response_status, :kind => :http_log, :state => :exception
          Benelux.current_track.remove_tags :status, :request, :stella_id
          break
          
        rescue => ex
          Stella.le "[#{ex.class}] #{ex.message}", ex.backtrace
          log = Stella::Log::HTTP.new Stella.now, @session.http_method, @session.uri, @session.params
          log.msg = ex.message
          tt.add_message log, :status => log.response_status, :kind => :http_log, :state => :fubar
          Benelux.current_track.remove_tags :status, :request, :stella_id
          break
          
        end
      end
      
    end
    
    def run_sleeper dur
      return unless dur && dur > 0
      dur = (rand * (dur.last-dur.first) + dur.first) if Range === dur
      debug "sleep: #{dur}"
      sleep dur
    end
    
    def debug(msg)
      Stella.ld " #{clientid.short} #{msg}"
    end
    
    def create_http_client
      http_client = HTTPClient.new(
        :agent_name  => @opts[:agent] || @opts['agent'] || Stella.agent,
        :from        => nil
      )
      #http_client.set_proxy_auth(@proxy.user, @proxy.pass) if @proxy.user
      #http_client.debug_dev = STDOUT if Stella.debug?
      http_client.protocol_version = "HTTP/1.1"
      if @opts[:ssl_verify_mode]
        http_client.ssl_config.verify_mode = @opts[:ssl_verify_mode]
      end
      
      # See: http://ghouston.blogspot.com/2006/03/using-ssl-with-ruby-http-access2.html
      begin 
        http_client.ssl_config.clear_cert_store
        http_client.ssl_config.set_trust_ca SSL_CERT_PATH
      rescue => ex
        Stella.li ex.class, ex.message
        Stella.ld ex.backtrace
      end
      
      http_client.connect_timeout = @opts[:timeout]
      http_client.send_timeout = @opts[:timeout]
      http_client.receive_timeout = @opts[:timeout]
      http_client
    end
    
    def done!
      @done = true
    end
    
    def done?
      @done == true
    end
    
  end
  
  class Session
    attr_reader :events, :response_handler, :res, :req, :rt, :vars, :previous_doc, :http_auth
    attr_accessor :headers, :params, :base_uri, :http_client, :uri, :redirect_uri, :http_method, :exception
    def initialize(base_uri=nil)
      @base_uri = base_uri
      @vars = indifferent_hash
      @base_uri &&= Addressable::URI.parse(@base_uri) if String === @base_uri
      @events = SelectableArray.new
    end
    def current_event
      @events.last
    end
    alias_method :param, :params
    alias_method :header, :headers
    def prepare_request uc, rt
      clear_previous_request
      @rt = rt
      @vars.merge! uc.class.session || {}
      @vars.merge! uc.class.testplan.class.session || {}
      registered_classes = uc.class.testplan.class.registered_classes || []
      registered_classes.push *(uc.class.registered_classes || [])
      registered_classes.each do |klass| 
        self.extend klass unless self.kind_of?(klass)
      end
      @http_method, @params, @headers = rt.http_method, rt.params, rt.headers
      @http_auth = uc.http_auth
      instance_exec(&rt.callback) unless rt.callback.nil?
      @uri = if @redirect_uri
        @params = {}
        @headers = {}
        @http_method = :get
        if @redirect_uri.scheme
          tmp = [@redirect_uri.scheme, '://', @redirect_uri.host].join
          tmp << ":#{@redirect_uri.port}" unless [80,443].member?(@redirect_uri.port)
          @base_uri = Addressable::URI.parse(tmp)
        end
        build_uri @redirect_uri
      else
        build_uri @rt.uri
      end
      if !http_auth.nil? && !http_auth.empty?
        Stella.ld " HTTP AUTH: #{http_auth.inspect}"
        http_auth[:domain] ||= '%s://%s:%d%s' % [base_uri.scheme, base_uri.host, base_uri.port, '/'] 
        http_client.set_auth http_auth[:domain], http_auth[:user], http_auth[:pass]
        Stella.ld "   #{http_client.www_auth.inspect}"
      end
      @redirect_uri = nil  # one time deal
    end
    def generate_request(event_id)
      @res = http_client.send(@http_method.to_s.downcase, @uri, params, headers)
      @req = @res.request
      @events << event_id
      @res
    end
    def location
      @location ||= Addressable::URI.parse(@res.header['location'].first || '')
      @location
    end
    def redirect?
      @res && (300..399).member?(@res.status)
    end
    def doc
      return @doc unless @doc.nil?
      return nil if @res.content.nil? || @res.content.empty?
      str = RUBY_VERSION >= "1.9.0" ? @res.content.force_encoding("UTF-8") : @res.content
      # NOTE: It's important to parse the document on every 
      # request because this container is available for the
      # entire life of a usecase. 
      @doc = case (@res.header['Content-Type'] || []).first
      when /text\/html/
        Nokogiri::HTML(str)
      when /text\/xml/
        Nokogiri::XML(str)
      when /text\/yaml/
        YAML.load(str)
      when /application\/json/
        Yajl::Parser.parse(str)
      end
      @doc.replace indifferent_params(@doc) if Hash === @doc
      @doc
    end
    def form
      return @form unless @form.nil?
      return nil if doc.nil?
      return nil unless content_type?('text/html')
      @form = indifferent_hash
      forms = doc.css('form')
      forms.each_with_index do |html,idx|
        name = html['id'] || html['name'] || html['class']
        Stella.ld [:form, idx, name].inspect
        form = indifferent_hash
        # Store form attributes in keys prefixed with an underscore.
        html.each { |att,val| form["_#{att}"] = val }
        # Store input name and values in the form hash.
        html.css('input').each do |input|
          form[input['name']] = input['value']
        end
        # Store the form by the name and index in the document
        @form[name] = @form[idx] = form
      end
      @form
    end
    alias_method :forms, :form
    def cookie
      return @cookie unless @cookie.nil?
      return nil unless http_client.cookie_manager
      return nil if http_client.cookie_manager.cookies.empty?
      @cookie = indifferent_hash
      http_client.cookie_manager.cookies.each do |c|
        next unless c.match?(uri)
        @cookie[c.name] = c.value
      end
      @cookie
    end
    alias_method :cookies, :cookie
    def content_type? guess
      guess = Regexp.new guess unless Regexp === guess
      guess.match((res.header['Content-Type'] || []).first)
    end
    def handle_response
      return unless response_handler?
      instance_exec(&find_response_handler(@res.status))
      @previous_doc = doc
    end
    def find_response_handler(status)
      return if response_handler.nil?
      key = response_handler.keys.select { |range| range.member?(status) }.first
      response_handler[key] if key
    end
    def response_handler?
      status = (@res.status || 0).to_i
      !find_response_handler(status).nil?
    end
    def response_handler(range=nil, &blk)
      @response_handler ||= {}
      return @response_handler if range.nil? && blk.nil?
      range = 0..999 if range.nil? || range.zero?
      range = range.to_i..range.to_i unless Range === range
      @response_handler[range] = blk unless blk.nil?
      @response_handler[range]
    end
    alias_method :handler, :response_handler
    alias_method :response, :response_handler
    alias_method :session, :vars
    def clear_previous_request
      [:doc, :location, :res, :req, :rt, :params, :headers, :cookie, :form, :response_handler, :http_method, :exception].each do |n|
        instance_variable_set :"@#{n}", nil
      end
    end
    def status
      @res.status
    end
    
    def wait(t); sleep t; end
    def quit(msg=nil); raise TestplanQuit.new(msg); end
    def fail(msg=nil); raise UsecaseFail.new(msg); end
    def error(msg=nil); raise RequestError.new(msg); end
    def repeat(t=1); raise RepeatRequest.new(t); end
    def follow(uri=nil,&blk); raise ForcedRedirect.new(uri,&blk); end
    
    private 
    def build_uri(reqtempl)
      uri = reqtempl.clone # need to clone b/c we modify uri in scan.
      reqtempl.to_s.scan(/([:\$])([a-z_]+)/i) do |inst|
        val = find_replacement_value(inst[1])
        Stella.ld " FOUND VAR: #{inst[0]}#{inst[1]} (value: #{val})"
        if val.nil?
          raise Stella::UsecaseError, "no value for #{inst[0]}#{inst[1]} in '#{@rt.uri}'"
        end
        re = Regexp.new "\\#{inst[0]}#{inst[1]}"
        uri.gsub! re, val.to_s unless val.nil?
      end
      uri = Stella.canonical_uri(uri)
      if base_uri
        uri.scheme = base_uri.scheme
        uri.host = base_uri.host if uri.host.to_s.empty?
        uri.port = base_uri.port if uri.port.to_s.empty?
      end
      uri
    end
    # Testplan URIs can contain variables in the form <tt>:varname</tt>. 
    # This method looks at the request parameters and then at the 
    # usecase's resource hash for a replacement value. 
    # If not found, returns nil. 
    def find_replacement_value(name)
      if @params.has_key?(name.to_sym)
        @params.delete name.to_sym
      elsif vars.has_key?(name.to_s) || vars.has_key?(name.to_s.to_sym)
        vars[name.to_s] || vars[name.to_s.to_sym]
      elsif Stella::Testplan.global?(name)
        Stella::Testplan.global(name)
      end
    end
    def indifferent_params(params)
      if params.is_a?(Hash)
        params = indifferent_hash.merge(params)
        params.each do |key, value|
          next unless value.is_a?(Hash) || value.is_a?(Array)
          params[key] = indifferent_params(value)
        end
      elsif params.is_a?(Array)
        params.collect! do |value|
          if value.is_a?(Hash) || value.is_a?(Array)
            indifferent_params(value)
          else
            value
          end
        end
      end
    end

    # Creates a Hash with indifferent access.
    def indifferent_hash
      Hash.new {|hash,key| hash[key.to_s] if Symbol === key }
    end
  end
  
  module Asserts
    def assert_doc
      fail 'No content' if doc.nil?
    end
    
    def assert_keys expected_keys 
      assert_doc
      found_keys = doc.keys.uniq.sort
      unless found_keys == expected_keys
        quit "Doc keys mismatch (#{found_keys})"
      end
    end
    
    def assert_list key
      assert_doc
      fail "#{key} is empty" if doc[key].nil? || doc[key].empty?
    end
    
    def assert_object_keys key, expected_keys
      assert_doc
      found_keys = doc[key].collect { |obj| obj.keys }.flatten.uniq.sort
      unless found_keys == expected_keys
        quit "Doc keys mismatch (#{found_keys})"
      end
    end
    
    def assert_object_values key, object_key, expected_values
      expected_values = [expected_values] unless Array === expected_values
      expected_values = expected_values.collect { |v| v.to_s }.sort
      values_found = doc[key].collect { |obj| obj[object_key].to_s }
      values_found.sort!
      unless values_found.uniq == expected_values
        quit "#{key} contains unexpected values for #{object_key}: #{values_found.uniq}"
      end
    end
    
    def assert_form name
      assert_doc
      fail "No form called #{name}" unless form && form[name]
    end
    def assert_exists v
      fail "Found nil value" if v.nil?
      fail "Found empty value" if v.empty?
    end
    def assert_equals expected, found
      fail "Expected: #{expected}; Found: #{found}" unless expected == found
    end
    def assert_matches regex, found
      fail "Expected: #{regex}; Found: #{found}" unless regex.match(found)
    end
    alias_method :assert_match, :assert_matches
    
  end
  
end
