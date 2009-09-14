
module Stella
class Testplan

  class Stats
    include Gibbler::Complex
    attr_reader :requests

    def initialize
      @requests = OpenStruct.new
      reset
    end
    
    def total_requests
      @requests.successful + @requests.failed
    end
    
    def reset 
      @requests.successful = 0
      @requests.failed = 0
    end
    
  end
    
end
end