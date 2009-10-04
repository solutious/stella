

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
  
  #Benelux.add_counter Stella::Client, :execute_response_handler
  
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
    end
    
    def update_repeat_request client_id, counter, total
    end
    
    def update_stats client_id, http_client, usecase, req
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