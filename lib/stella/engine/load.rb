
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
      
      thread_package, pointer = Array.new(opts[:users]), 0
      plan.usecases.each_with_index do |usecase,i|
        count = opts[:users] < 10 ? (opts[:users]/2) : (opts[:users] * usecase.ratio).to_i
        Stella.ld "EXPANDING USECASES: "
        Stella.ld "#{usecase.desc} #{pointer} #{(pointer+count-1)}"
        # Fill the thread_package with the contents of the block
        thread_package.fill(pointer, count) do |index|
          Stella.li2 "Creating client ##{index}"
          client = Stella::Client.new opts[:hosts].first, index
          client.add_observer(self)
          client.enable_benchmark_mode if opts[:benchmark]
          [[index, client, usecase.clone]]  # Why does fill need a nested Array
        end
        pointer += count == 1 ? 1 : count-1
      end
      
      puts thread_package.size
      exit
      Thread.ify thread_package, :threads => opts[:users] do |package|
        index, client, usecase = *package
        p index
        (1..opts[:repetitions]).to_a.each do |rep|
          # We store client specific data in the usecase
          # so we clone it here so each thread is unique.
          Stella.rescue { client.execute usecase }
        end
      
      end

      Drydock::Screen.flush
    end
    
    
    
    def update_send_request(client_id, usecase, meth, uri, req, params, counter)
      
    end
    
    def update_receive_response(client_id, usecase, meth, uri, req, params, container)
      Drydock::Screen.puts '%3s (%s): %s %-6s %3s %s' % [client_id, usecase.desc, req.desc, req.http_method, container.status, uri]
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

