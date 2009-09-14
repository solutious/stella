

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
        Stella.ld "NO UPDATE HANDLER FOR: #{what}" 
      else
        Stella.rescue {
          self.send("update_#{what}", *args) 
        }
      end
    end
    
    def update_send_request(meth, uri, req)
      Stella.li2 ' ' << " %-64s ".att(:reverse) % req.desc
    end
    
    def update_receive_response(uri, req, container)
      Stella.li '  %-60s %3d' % [uri, container.status]
      Stella.li3 $/, "  Headers:"
      container.headers.all.each do |pair|
        Stella.li3 "    %s: %s" % pair
      end
      Stella.li2 $/, "  Content:"
      Stella.li2 container.body

    end
    
    def update_execute_response_handler(req, container)
    end
    
  end
end

Stella::Utils.require_glob(STELLA_LIB_HOME, 'stella', 'engine', '*.rb')