
require 'utils/httputil'

module Stella::Data
  class HTTPRequest < Stella::Storable
    attr_accessor :time, :client_ip, :server_ip, :header, :uri, :body, :method, :http_version 
    attr_reader :raw_data
    
    def initialize(raw_data=nil)
      @raw_data = raw_data
      if @raw_data
        @method, @http_version, @uri, @header, @body = HTTPUtil::parse_http_request(raw_data) 
      end
    end
    
    def field_names
      [ :time, :client_ip, :server_ip, :header, :uri, :body, :method, :http_version ]
    end
    
    def to_s
      str = "%s: %s %s HTTP/%s" % [@time, @method, @uri.to_s, @http_version]
      str << @body if @method =~ /POST|PUT|DELETE/
      str
    end
    
  end
  
  class HTTPResponse < Stella::Storable
    attr_accessor :time, :client_ip, :server_ip, :header, :body, :status, :message, :http_version
    attr_reader :raw_data
    
    def initialize(raw_data=nil)
      @raw_data = raw_data
      if @raw_data
        @status, @http_version, @message, @header, @body = HTTPUtil::parse_http_response(@raw_data)
      end
    end
        
    def field_names
      [ :time, :client_ip, :server_ip, :header, :body, :status, :message, :http_version ]
    end
    
    def to_s
      str = "%s: HTTP/%s %s (%s)" % [@time, @http_version, @status, @message]
      str << @body if @method =~ /POST|PUT|DELETE/
      str 
    end
  end
end 