

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
    
    def update_send_request(client_id, usecase, meth, uri, req, params, counter)
      notice = "repeat: #{counter-1}" if counter > 1
      Stella.li2 ' ' << " %-46s %16s ".att(:reverse) % [req.desc, notice]
    end
    
    def update_receive_response(client_id, usecase, meth, uri, req, params, container)
      Stella.li '  %-59s %3d' % [uri, container.status]
      Stella.li2 "  Method: " << req.http_method
      Stella.li2 "  Params: " << params.inspect
      Stella.li3 $/, "  Headers:"
      container.headers.all.each do |pair|
        Stella.li3 "    %s: %s" % pair
      end
      Stella.li4 $/, "  Content:"
      Stella.li4 container.body.empty? ? '    [empty]' : container.body
      Stella.li2 $/
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
      Stella.le ex.message
    end
    
    def update_request_error(client_id, usecase, meth, uri, req, params, ex)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.le '  Client%-3s %-45s %s' % [client_id, desc, ex.message]
      Stella.ld ex.backtrace
    end
    
  end
end

Stella::Utils.require_glob(STELLA_LIB_HOME, 'stella', 'engine', '*.rb')