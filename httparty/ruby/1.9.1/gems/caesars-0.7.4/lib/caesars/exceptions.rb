

class Caesars
  class Error < RuntimeError
    attr_accessor :backtrace
    def initialize(obj=nil); @obj = obj; end
    def message; "#{self.class}: #{@obj}"; end
  end
  class SyntaxError < Caesars::Error
    def message
      msg = "Syntax error in #{@obj}"
      bt = @backtrace 
      msg << " in " << bt.first.scan(/\`(.+?)'/).flatten.first if bt
      msg
    end
  end
end