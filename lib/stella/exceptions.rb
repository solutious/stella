

module Stella
  class Error < RuntimeError
    def initialize(obj=nil); @obj = obj; end
    def message; "#{self.class}: #{@obj}"; end
  end
  
  class WackyRatio < Stella::Error
  end
  
  class WackyDuration < Stella::Error
  end
  
  class InvalidOption < Stella::Error
  end
  
  class NoHostDefined < Stella::Error
  end  
end