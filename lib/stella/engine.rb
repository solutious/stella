

module Stella::Engine
  module Base
    extend self
    def run
      raise "override the run method"
    end
    
    def update(*args)
      what, *args = args
      Stella.ld "OBSERVER UPDATE: #{what}"
      if !respond_to?("update_#{what}")
        puts "NO UPDATE HANDLER FOR: #{what}" 
      else
        self.send("update_#{what}", *args) 
      end
    end
    
    def update_execute_uri(meth, uri, req)
      Stella.li " #{req.desc} ".att(:reverse)
      Stella.li " #{uri}"
    end
  end
end

Stella::Utils.require_glob(STELLA_LIB_HOME, 'stella', 'engine', '*.rb')