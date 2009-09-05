

module Stella::Data::HTTP
  
  class Request < Storable
    # A string representing a raw HTTP request
    attr_reader :raw_data
    
    # A hash containing blocks to be executed depending on the HTTP response status.
    # The hash keys are numeric HTTP Status Codes. 
    #
    #     200 => { ... }
    #     304 => { ... }
    #     500 => { ... }
    #
    attr_accessor :response_handler
    
    field :name
    field :stella_id
    field :unique_id
    field :time => DateTime
    field :client_ip 
    field :server_ip 
    field :header 
    field :uri
    field :params
    field :body 
    field :http_method
    field :http_version
    
    
    def has_body?
      !@body.nil? && !@body.empty?
    end
    def has_request?
      false
    end

    def initialize (uri_str, method="GET", version="1.1")
      @uri = (uri_str.is_a? String) ? URI.parse(uri_str) : uri
      @http_method = method
      @http_version = version
      @headers = {}
      @params = {}
      @response_handler = {}
      @time = Time.now.utc
      
      @unique_id = nil
      @body = Stella::Data::HTTP::Body.new
    end
    
    def set_unique_id(seasoning=rand)
      #@unique_id = Stella::Crypto.sign(rand.to_s + seasoning.to_s, "#{@http_method}/#{@uri}/#{@params}")
    end

    def stella_id
      #@stella_id = Stella::Crypto.sign(time.to_i.to_s, "#{@http_method}/#{@uri}/#{@params}")
    end
    
    def from_raw(raw_data=nil)
      @raw_data = raw_data
      @http_method, @http_version, @uri, @header, @body = self.parse(@raw_data)
      @time = DateTime.now
    end
    
    def self.parse(raw)
      return unless raw
      HTTPUtil::parse_http_request(raw, @uri.host, @uri.port) 
    end

    
    def add_header(*args)
      name, value = (args[0].is_a? Hash) ? args[0].to_a.flatten : args
      @headers[name.to_s] ||= []
      @headers[name.to_s] << value
    end
    def add_param(*args)
      name, value = (args[0].is_a? Hash) ? args[0].to_a.flatten : args
      
      # BUG: This auto-array shit is causing a problem where the one request
      # will set the param and then next will set it again and it becomes
      # an array. 
      #if @params[name.to_s] && !@params[name.to_s].is_a?(Array)
      #  @params[name.to_s] = [@params[name.to_s]]
      #else
      #  @params[name.to_s] = ""
      #end
      
      @params[name.to_s] = value.to_s
    end
    
    def add_response_handler(*args, &b)
      args << 200 if args.empty?
      args.each do |status|
        @response_handler[status] = b
      end
    end
    
    # +content+ can be literal content or a file path
    def add_body(content, form_param=nil, content_type=nil)
      @body = Stella::Data::HTTPBody.new
      
      @body.form_param = form_param if form_param
      @body.content_type = content_type if content_type
      
      if File.exists?(content)
        @body.content = File.new(content)
        @body.content_type ||= "application/x-www-form-urlencoded"
      else
        @body.content = content
      end
      
    end
    
    
    def body
      return nil unless @body
      @body
      #(!header || header[:Content_Type] || header[:Content_Type] !~ /text/) ? Base64.encode64(@body) : @body
    end
    

    def headers
      return [] unless header
      headers = []
      header.each_pair do |n,v|
        headers << [n.to_s.gsub('_', '-'), v[0]]
      end
      headers
    end
    
    def inspect
      str = "%s %s HTTP/%s" % [http_method, uri.to_s, http_version]
      str << $/ + headers.join($/) unless headers.empty?
      str << $/ + $/ + body.to_s if body
      str
    end
    
    def to_s
      str = "%s: %s %s HTTP/%s" % [time.strftime(NICE_TIME_FORMAT), http_method, uri.to_s, http_version]
      str
    end
    
    def cookies
      return [] if !header.is_a?(Hash) || header[:Cookie].empty?
      header[:Cookie] 
    end
    
  end
  
end