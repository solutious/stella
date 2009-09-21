
module Stella::Engine
  module Load
    extend Stella::Engine::Base
    extend self
    
    def run(plan, opts={})
      opts = {
        :hosts        => [],
        :clients        => 1,
        :time         => nil,
        :benchmark    => false,
        :repetitions  => 1
      }.merge! opts
      opts[:clients] = plan.usecases.size if opts[:clients] < plan.usecases.size
      opts[:clients] = 1000 if opts[:clients] > 1000
      
      Stella.ld "OPTIONS: #{opts.inspect}"
      Stella.li3 "Hosts: " << opts[:hosts].join(', ')
      Stella.li2 plan.pretty
      
      packages = build_thread_package plan, opts
      Stella.li $/, "Prepared #{packages.size} virtual clients..."
      Stella.lflush
      
      
      Stella.li $/, "Starting test...", $/
      Stella.lflush
      sleep 0.3
      
      
      Thread.ify packages, :threads => opts[:clients] do |package|
        # TEMPFIX. The fill in build_thread_package is creating nil elements
        next if package.nil? 
        (1..opts[:repetitions]).to_a.each do |rep|
          # We store client specific data in the usecase
          # so we clone it here so each thread is unique.
          Stella.rescue { package.client.execute package.usecase }
        end
        
        #package.client.benelux_timeline.each do |i|
        #  Stella.li "#{package.client.client_id}: #{i.to_f}: #{i.name}"
        #end
        #t = Benelux.thread_timeline.sort
        #dur = t.last.to_f - t.first.to_f
        #Stella.li [:thread, t.first.name, t.last.name, dur].inspect
        #Stella.lflush
      end
      
      #t = Benelux.timeline.sort
      #dur = t.last.to_f - t.first.to_f
      #Stella.li [:global, t.first.name, t.last.name, dur].inspect
      
      #puts Thread.list
      #p Benelux.timeline
      
      prev = nil
      #Stella.li Benelux.timeline.sort.collect { |obj|
      #  str = "#{obj.to_f}: #{obj.name} (#{obj.same_timeline?(prev)})" 
      #  prev = obj
      #  str
      #}
      !plan.errors?
    end
    
  protected
    class ThreadPackage
      attr_accessor :index
      attr_accessor :client
      attr_accessor :usecase
      def initialize(i, c, u)
        @index, @client, @usecase = i, c, u
      end
    end
    
    def build_thread_package(plan, opts)
      packages, pointer = Array.new(opts[:clients]), 0
      plan.usecases.each_with_index do |usecase,i|
        
        count = case opts[:clients]
        when 0..9
          if (opts[:clients] % plan.usecases.size > 0) 
            msg = "Client count does not evenly match usecase count"
            raise Stella::Testplan::WackyRatio, msg
          else
            (opts[:clients] / plan.usecases.size)
          end
        else
          (opts[:clients] * usecase.ratio).to_i
        end
        
        Stella.ld "THREAD PACKAGE: #{usecase.desc} (#{pointer} + #{count})"
        # Fill the thread_package with the contents of the block
        packages.fill(pointer, count) do |index|
          Stella.li2 "Creating client ##{index+1} "
          client = Stella::Client.new opts[:hosts].first, index+1
          client.add_observer(self)
          client.enable_benchmark_mode if opts[:benchmark]
          ThreadPackage.new(index+1, client, usecase.clone)
        end
        pointer += count
      end
      packages
    end
    
    
    def update_prepare_request(client_id, usecase, req, counter)

    end
    
    def update_send_request(client_id, usecase, uri, req, params, counter)
      
    end
    
    def update_receive_response(client_id, usecase, uri, req, params, container)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.li2 '  Client%-3s %3d %-6s %-45s %s' % [client_id, container.status, req.http_method, desc, uri]
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
    end
    
    def update_request_error(client_id, usecase, uri, req, params, ex)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.le '  Client%-3s %-45s %s' % [client_id, desc, ex.message]
      Stella.ld ex.backtrace
    end

    
  end
end

__END__


$ stella verify -p examples/basic/plan.rb http://localhost:3114
$ stella load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-verify -p examples/basic/plan.rb http://localhost:3114

