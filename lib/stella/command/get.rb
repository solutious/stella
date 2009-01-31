
require 'stella/command/base'
require 'stella/data/http'


module Stella::Command
  class Get < Stella::Command::Base
    
    attr_accessor :raw
    
    def initialize(raw=nil)
      @raw = raw if raw
    end
    
    def run
      puts @raw
    end
    
  end
end