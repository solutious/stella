
      
module Stella::Command
  class Base
    
    attr_accessor :quiet
    attr_accessor :guid
    attr_accessor :verbose
    attr_accessor :format
    attr_accessor :force
    
    def run
      raise "Override 'run'"
    end
    
    def run_sleeper(duration)
      remainder = duration % 1 
      duration.to_i.times {
        Stella::LOGGER.info_print('.') unless @quiet
        sleep 1
      }
      sleep remainder if remainder > 0
    end
    


  end
end