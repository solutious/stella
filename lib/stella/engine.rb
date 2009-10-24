

module Stella::Engine
  
  module Base
    extend self
    
    @@client_limit = 200
    
    def update(*args)
      what, *args = args
      if respond_to?("update_#{what}")
        #Stella.ld "OBSERVER UPDATE: #{what}"
        Stella.rescue { self.send("update_#{what}", *args) }
      else
        Stella.ld "NO UPDATE HANDLER FOR: #{what}" 
      end
    end

    def process_options!(plan, opts={})
      opts = {
        :hosts          => [],
        :clients        => 1,
        :duration       => 0,
        :nowait         => false,
        :arrival        => nil,
        :repetitions    => 1
      }.merge! opts
      
      Stella.li3 " Options: #{opts.inspect}"
      Stella.lflush
      
      opts[:clients] = plan.usecases.size if opts[:clients] < plan.usecases.size
      
      if opts[:clients] > @@client_limit
        Stella.li3 "Client limit is #{@@client_limit}"
        opts[:clients] = @@client_limit
      end
      
      # Parses 60m -> 3600. See mixins. 
      if opts[:duration].in_seconds.nil?
        raise Stella::WackyDuration, opts[:duration] 
      end
      
      opts[:duration] = opts[:duration].in_seconds
      
      Stella.li3 " Hosts: " << opts[:hosts].join(', ')
      opts
    end
    
    def run; raise; end
    def update_quit_usecase(client_id, msg) raise end
    def update_repeat_request(client_id, counter, total) raise end
    def update_stats(client_id, http_client, usecase, req) raise end
    def update_prepare_request(*args) raise end
    def update_send_request(*args) raise end
    def update_receive_response(*args) raise end
    def update_execute_response_handler(*args) raise end
    def update_error_execute_response_handler(*args) raise end
    def update_request_error(*args) raise end
    
  end
  
  autoload :Functional, 'stella/engine/functional'
  autoload :Load, 'stella/engine/loadbase'
  autoload :LoadPackage, 'stella/engine/load_package'
  autoload :LoadCreate, 'stella/engine/load_create'
  autoload :LoadQueue, 'stella/engine/load_queue'
  
  # These timers are interesting from a reporting perspective.
  Benelux.add_counter    Stella::Client, :execute_response_handler
  Benelux.add_timer          HTTPClient, :do_request
  ## These are contained in connect
  #Benelux.add_timer HTTPClient::Session, :create_socket
  #Benelux.add_timer HTTPClient::Session, :create_ssl_socket
  Benelux.add_timer HTTPClient::Session, :connect
  Benelux.add_timer HTTPClient::Session, :query
  Benelux.add_timer HTTPClient::Session, :socket_gets_first_byte
  Benelux.add_timer HTTPClient::Session, :get_body

end

