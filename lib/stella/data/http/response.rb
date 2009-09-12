

module Stella::Data::HTTP
  
  class Response < Storable
    include Gibbler::Complex
    
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