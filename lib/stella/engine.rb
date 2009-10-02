

module Stella::Engine
  
  # These commented out timers are not very revealing.
  #Benelux.add_timer      Stella::Client, :execute
  #Benelux.add_timer      Stella::Client, :send_request
  #Benelux.add_timer          HTTPClient, :create_request
  
  # These timers are interesting from a reporting perspective.
  Benelux.add_timer          HTTPClient, :do_request
  Benelux.add_timer HTTPClient::Session, :create_socket
  Benelux.add_timer HTTPClient::Session, :create_ssl_socket
  Benelux.add_timer HTTPClient::Session, :connect
  Benelux.add_timer HTTPClient::Session, :query
  Benelux.add_timer HTTPClient::Session, :socket_gets_first_byte
  Benelux.add_timer HTTPClient::Session, :get_body

  module Base
    extend self
    
    def update(*args)
      what, *args = args
      if respond_to?("update_#{what}")
        Stella.ld "OBSERVER UPDATE: #{what}"
        Stella.rescue { self.send("update_#{what}", *args) }
      else
        Stella.ld "NO UPDATE HANDLER FOR: #{what}" 
      end
    end

    def run; raise; end
    
    
    def update_quit_usecase client_id, msg
      Stella.li2 "  Client-%s     QUIT   %s" % [client_id.shorter, msg]
    end
    
    
    def update_repeat_request client_id, counter, total
      Stella.li3 "  Client-%s     REPEAT   %d of %d" % [client_id.shorter, counter, total]
    end
    
    def update_stats client_id, http_client, usecase, req
      #range = Thread.current.timeline.ranges(:do_request).last
      #Thread.current.stathash 
      #Stella.li "Client-%s: %s-%s %s %.4f" % [client_id.short, usecase.gibbler.short, req.gibbler.short, req.desc, range.duration]
    end
    
    def update_prepare_request(*args) raise end
    def update_send_request(*args) raise end
    def update_receive_response(*args) raise end
    def update_execute_response_handler(*args) raise end
    def update_error_execute_response_handler(*args) raise end
    def update_request_error(*args) raise end
    
  end
end

Stella::Utils.require_glob(Stella::LIB_HOME, 'stella', 'engine', '*.rb')