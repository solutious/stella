

class Stella::Client
  
  class ResponseModifier; end
  class Repeat < ResponseModifier; 
    attr_accessor :times
    def initialize(times)
      @times = times
    end
  end
  class Quit < ResponseModifier; 
    attr_accessor :message
    def initialize(msg=nil)
      @message = msg
    end
  end
  class Fail < Quit; end
  
end