
require 'utils/httputil'
require 'base64'

module Stella::Data
  class HTTPRequest < Stella::Storable
    attr_accessor :time, :client_ip, :server_ip, :header, :body, :method, :http_version 
    attr_reader :raw_data
    attr_writer :uri, :body
    
    def initialize(raw_data=nil)
      @raw_data = raw_data
      if @raw_data
        @method, @http_version, @uri, @header, @body = HTTPUtil::parse_http_request(raw_data) 
      end
    end
    
    def uri
      @uri.host = @server_ip.to_s if @uri && (@uri.host == 'unknown' || @uri.host.empty?)
      @uri
    end
    
    def body
      return nil unless @body
      (!header || header[:Content_Type] || header[:Content_Type] !~ /text/) ? Base64.encode64(@body) : @body
    end
    
    def field_names
      [ :time, :client_ip, :server_ip, :header, :uri, :body, :method, :http_version ]
    end
    
    def inspect
      headers = []
      header.each_pair do |n,v|
        headers << "#{n}: #{v[0]}"
      end
      str = "%s %s HTTP/%s" % [method, uri.to_s, http_version]
      str << $/ + headers.join($/)
      str << $/ + $/ + body if body
      str
    end
    
    def to_s
      str = "%s: %s %s HTTP/%s" % [time, method, uri.to_s, http_version]
      str << $/ + $/ + body if body && @method =~ /POST|PUT|DELETE/
      str
    end
    
  end
  
  class HTTPResponse < Stella::Storable
    attr_accessor :time, :client_ip, :server_ip, :header, :status, :message, :http_version
    attr_reader :raw_data
    attr_writer :body
    
    def initialize(raw_data=nil)
      @raw_data = raw_data
      if @raw_data
        @status, @http_version, @message, @header, @body = HTTPUtil::parse_http_response(@raw_data)
      end
    end
    
    def body
      return nil unless @body
      (!header || header[:Content_Type] || header[:Content_Type] !~ /text/) ? Base64.encode64(@body) : @body
    end
    
    def field_names
      [ :time, :client_ip, :server_ip, :header, :body, :status, :message, :http_version ]
    end
    
    def inspect
      headers = []
      header.each_pair do |n,v|
        headers << "#{n}: #{v[0]}"
      end
      str = "HTTP/%s %s (%s)" % [@http_version, @status, @message]
      str << $/ + headers.join($/)
      str << $/ + $/ + body if body
      str
    end
    
    def to_s
      str = "%s: HTTP/%s %s (%s)" % [@time, @http_version, @status, @message]
      str << $/ + $/ + body if body
      str 
    end
  end
end 