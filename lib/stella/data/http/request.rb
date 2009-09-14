

module Stella::Data::HTTP
  class Request < Storable
    include Gibbler::Complex
    include Stella::Data::Helpers
    
    # A hash containing blocks to be executed depending on the HTTP response status.
    # The hash keys are numeric HTTP Status Codes. 
    #
    #     200 => { ... }
    #     304 => { ... }
    #     500 => { ... }
    #
    attr_accessor :response_handler
    
    field :desc
    field :header 
    field :uri
    field :wait
    field :params
    field :body 
    field :http_method
    field :http_version
    field :content_type
    
    def has_body?
      !@body.nil? && !@body.empty?
    end
    
    def initialize (method, uri_str, version="1.1", &definition)
      @uri = (uri_str.is_a? String) ? URI.parse(uri_str) : uri
      @http_method, @http_version = method, version
      @headers, @params, @response_handler = {}, {}, {}
      @wait = 0
      @desc = "Request"
      @body = Stella::Data::HTTP::Body.new
      instance_eval &definition unless definition.nil?
    end
    
    def desc(*args)
      @desc = args.first unless args.empty?
      @desc
    end
    
    def content_type(*args)
      @content_type = args.first unless args.empty?
      @content_type
    end
    
    def wait(*args)
      @wait = args.first unless args.empty?
      @wait
    end
    alias_method :sleep, :wait
    
    def headers(*args)
      @headers.merge! args.first unless args.empty?
      @headers
    end
    alias_method :header, :headers
    
    def params(*args)
      @params.merge! args.first unless args.empty?
      @params
    end
    alias_method :param, :params
    
    def response(*args, &definition)
      if definition.nil?
        @response_handler
      else
        args << 200 if args.empty?
        args.each do |status|
          @response_handler[status] = definition
        end
      end
    end
    
    # +content+ can be literal content or a file path
    def body(*args)
      return @body if args.empty?
      content, form_param, content_type = *args
      
      @body.form_param = form_param if form_param
      @body.content_type = content_type if content_type
      
      if File.exists?(content)
        @body.content = File.new(content)
        @body.content_type ||= "application/x-www-form-urlencoded"
      else
        @body.content = content
      end
      
    end
    
    def inspect
      str = "%s %s HTTP/%s" % [http_method, uri.to_s, http_version]
      str << $/ + headers.join($/) unless headers.empty?
      str << $/ + $/ + body.to_s if body
      str
    end
    
    def to_s
      str = "%s %s HTTP/%s" % [http_method, uri.to_s, http_version]
      str
    end
    
    def cookies
      return [] if !header.is_a?(Hash) || header[:Cookie].empty?
      header[:Cookie] 
    end
    
  end
  
end