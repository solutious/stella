
require 'httpclient'

require 'util/httputil'

require 'stella/command/base'
require 'stella/data/http'


module Stella::Command
  class Get < Drydock::Command
    include Stella::Command::Base
    
    attr_accessor :raw
    attr_accessor :uri
    attr_accessor :proxy
    
    def run
      @req ||= req
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

    end
    
  end
end