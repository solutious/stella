
require 'storable'
require 'util/httputil'
require 'base64'

module Stella::Data
  
  # TODO: Implement HTTPHeaders. We should be printing untouched headers. 
  # HTTPUtil should split the HTTP event lines and that's it. Replace 
  # parse_header_body with split_header_body
  class HTTPHeaders < Storable
    attr_reader :raw_data
    
    def to_s
      @raw_data
    end
    
  end
  
  class HTTPBody < Storable
    field :content_type
    field :form_param
    field :content
    
    def has_content?
      !@content.nil?
    end
    
  end
  
  class HTTPRequest < Storable
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
      @time = Time.now
      @stella_id = Stella::Crypto.sign(time.to_i.to_s, "#{@http_method}/#{@uri}/#{@params}")
      @unique_id = nil
      @body = HTTPBody.new
    end
    
    def set_unique_id(seasoning=rand)
      @unique_id = Stella::Crypto.sign(rand.to_s + seasoning.to_s, "#{@http_method}/#{@uri}/#{@params}")
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
  
  class HTTPResponse < Storable
    attr_reader :raw_data
    
    field :time => DateTime
    field :client_ip => String
    field :server_ip => String
    field :header => String
    field :body => String
    field :status => String
    field :message => String
    field :http_version => String
    
    def initialize(raw_data=nil)
      @raw_data = raw_data
      parse(@raw_data)
    end
    
    def parse(raw)
      return unless raw
      @status, @http_version, @message, @header, @body = HTTPUtil::parse_http_response(raw)
    end
    
    def has_body?
      !@body.nil? && !@body.empty?
    end
    def has_request?
      false
    end
    def has_response?
      false
    end
    
    
    def body
      return nil unless @body
      #TODO: Move to HTTPResponse::Body.to_s
      if is_binary?
       "[skipping binary content]"
      elsif is_gzip?
        #require 'zlib'
        #Zlib::Inflate.inflate(@body)
         "[skipping gzip content]"
      else
        @body
      end
    end
    
    def headers
      headers = []
      header.each_pair do |n,v|
        headers << [n.to_s.gsub('_', '-'), v[0]]
      end
      headers
    end
    
    def is_binary?
      (!is_text?) == true
    end
    
    def is_text?
      (!header[:Content_Type].nil? && (header[:Content_Type][0].is_a? String) && header[:Content_Type][0][/text/] != nil)
    end
    
    def is_gzip?
      (!header[:Content_Encoding].nil? && (header[:Content_Encoding][0].is_a? String) && header[:Content_Encoding][0][/gzip/] != nil)
    end
    
    def inspect
      str = "HTTP/%s %s (%s)" % [@http_version, @status, @message]
      str << $/ + headers.join($/)
      str << $/ + $/ + body if body
      str
    end
    
    def to_s
      str = "%s: HTTP/%s %s (%s)" % [time.strftime(NICE_TIME_FORMAT), @http_version, @status, @message]
      str 
    end
    
    
    def cookies
      return [] unless header.is_a?(Array) && !header[:Set_Cookie].empty?
      header[:Set_Cookie] 
    end
  end
end 