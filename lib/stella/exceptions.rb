

module Stella
  class Error < RuntimeError
    def initialize(obj=nil); @obj = obj; end
    def message; "#{self.class}: #{@obj}"; end
  end
  
  class InvalidOption < Stella::Error
  end
  
end