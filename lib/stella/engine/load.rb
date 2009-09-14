
module Stella::Engine
  module Load
    extend Stella::Engine::Base
    extend self
    
    def run(plan, opts={})
      opts = {
        :hosts        => [],
        :users        => 1,
        :time         => nil,
        :benchmark    => false,
        :repetitions  => 1
      }.merge! opts
      Stella.ld "OPTIONS: #{opts.inspect}"
      Stella.li2 "Hosts: " << opts[:hosts].join(', ')
      
      thread_package = build_thread_package plan, opts
      
      Thread.ify thread_package, :threads => opts[:users] do |package|
        index, client, usecase = *package
        
        (1..opts[:repetitions]).to_a.each do |rep|
          # We store client specific data in the usecase
          # so we clone it here so each thread is unique.
          Stella.rescue { client.execute usecase }
          Drydock::Screen.flush
        end
      
      end
      
    end
    
  protected
    def build_thread_package(plan, opts)
      thread_package, pointer = Array.new(opts[:users]), 0
      plan.usecases.each_with_index do |usecase,i|
        
        count = case opts[:users]
        when 0..9
          if (opts[:users] % plan.usecases.size > 0) 
            raise Stella::Testplan::WackyRatio, "User count does not match usecase count evenly"
          else
            (opts[:users] / plan.usecases.size)
          end
        else
          (opts[:users] * usecase.ratio).to_i
        end
        
        Stella.ld "THREAD PACKAGE: #{usecase.desc} #{pointer} #{(pointer+count)} #{count}"
        # Fill the thread_package with the contents of the block
        thread_package.fill(pointer, count) do |index|
          Stella.li2 "Creating client ##{index+1}"
          client = Stella::Client.new opts[:hosts].first, index+1
          client.add_observer(self)
          client.enable_benchmark_mode if opts[:benchmark]
          [[index+1, client, usecase.clone]]  # Why does fill need a nested Array
        end
        pointer += count
      end
      thread_package
    end
    
    def update_send_request(client_id, usecase, meth, uri, req, params, counter)
      
    end
    
    def update_receive_response(client_id, usecase, meth, uri, req, params, container)
      desc = "#{usecase.desc}:#{req.desc}"
      Stella.li 'Client%-3s %3d %-6s %-45s  %s' % [client_id, container.status, req.http_method, uri, desc]
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
    end
    
    def update_request_error(client_id, usecase, meth, uri, req, params, ex)
      desc = "#{usecase.desc}:#{req.desc}"
      Stella.le 'Client%-3s %-45s  %s' % [client_id, ex.message, desc]
    end
    
  end
end

__END__


$ stella verify -p examples/basic/plan.rb http://localhost:3114
$ stella load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-verify -p examples/basic/plan.rb http://localhost:3114
