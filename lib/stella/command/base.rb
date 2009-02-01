
      
module Stella::Command
  module Base

    
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