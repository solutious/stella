
module Stella::Engine
  module Load
    extend Stella::Engine::Base
    extend self
    
    def run(plan, opts={})
      opts = {
        :hosts        => [],
        :users        => 1,
        :duration     => nil,
        :benchmark    => false,
        :repetitions  => 1
      }.merge! opts
      Stella.ld "OPTIONS: #{opts.inspect}"
      Stella.li2 "Hosts: " << opts[:hosts].join(', ')
      
      
      plan.usecases.each_with_index do |uc,i|
        desc = (uc.desc || "Usecase ##{i+1}")
        Drydock::Screen.puts ' %-65s '.att(:reverse).bright % [desc]
        
        (1..opts[:users]).to_a.threadify do |thread|
          if Stella.loglev > 1
            Drydock::Screen.puts "Creating client ##{thread} (#{Thread.current})"
          end
          client = Stella::Client.new opts[:hosts].first, thread
          client.add_observer(self)
          client.enable_benchmark_mode if opts[:benchmark]
          (1..opts[:repetitions]).to_a.each do |rep|
            # We store client specific data in the usecase
            # so we clone it here so each thread is unique.
            Stella.rescue { client.execute uc.clone }
          end
        end
      end
      
      
    end
    
    
    
    def update_send_request(client_id, meth, uri, req, params, counter)
      
    end
    
    def update_receive_response(client_id, meth, uri, req, params, container)
      Drydock::Screen.puts '%3d: %-6s %3s %s' % [client_id, req.http_method, container.status, uri]
      Drydock::Screen.flush
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
      Drydock::Screen.puts '!'
    end
  end
end

__END__


$ stella verify -p examples/basic/plan.rb http://localhost:3114
$ stella load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-verify -p examples/basic/plan.rb http://localhost:3114

