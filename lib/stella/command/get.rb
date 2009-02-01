
require 'stella/command/base'
require 'stella/data/http'


module Stella::Command
  class Get < Drydock::Command
    include Stella::Command::Base
    
    attr_accessor :raw
    
    def run

    end
    
  end
end