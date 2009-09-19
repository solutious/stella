

module Stella::Engine
  
  Benelux.add_timer Stella::Client, :execute
  Benelux.add_timer Stella::Client, :send_request
  
  Benelux.add_timer HTTPClient::Session, :create_socket
  Benelux.add_timer HTTPClient::Session, :connect
  Benelux.add_timer HTTPClient::Session, :query
  Benelux.add_timer HTTPClient::Session, :socket_gets_initial_line
  Benelux.add_timer HTTPClient::Session, :get_body
  
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
    
    def update_prepare_request(*args) raise end
    def update_send_request(*args) raise end
    def update_receive_response(*args) raise end
    def update_execute_response_handler(*args) raise end
    def update_error_execute_response_handler(*args) raise end
    def update_request_error(*args) raise end
    
  end
end

Stella::Utils.require_glob(Stella::LIB_HOME, 'stella', 'engine', '*.rb')