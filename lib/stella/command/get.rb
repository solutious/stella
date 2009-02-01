
require 'httpclient'

require 'util/httputil'

require 'stella/command/base'
require 'stella/data/http'


module Stella::Command
  class Get < Drydock::Command
    include Stella::Command::Base
    
    attr_accessor :raw
    attr_accessor :host
    attr_accessor :port
    attr_accessor :proxy
    
    def run
      @req = req if !@req && @raw
      raise "No request defined" unless @req
      c = (@proxy) ? HTTPClient.new(@proxy) : HTTPClient.new
      c.get @req.uri, @req.headers
    end
    
    def read_raw
      Stella.info("Enter the raw GET request:")
      @raw = gets
      while raw !~ /^#{$/}$/ 
        val = gets
        @raw << val if val
      end
      @raw
    end
    
    def req
      @req = Stella::Data::HTTPRequest.new(@raw)
    end
    
  end
end