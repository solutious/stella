
module Stella::Engine
  module Functional
    extend Stella::Engine::Base
    extend self
    
    def run(plan, opts={})
      opts = {
        :hosts        => [],
        :benchmark    => false,
        :repetitions  => 1
      }.merge! opts
      Stella.ld "OPTIONS: #{opts.inspect}"
      Stella.li2 "Hosts: " << opts[:hosts].join(', ') if !opts[:hosts].empty?
      Stella.li plan.pretty
      
      client = Stella::Client.new opts[:hosts].first
      client.add_observer(self)

      client.enable_benchmark_mode if opts[:benchmark]
      
      Stella.li $/, "Starting test...", $/
      Stella.lflush
      sleep 0.3
      
      benelux_timeline = Benelux::Timeline.new
      plan.usecases.each_with_index do |uc,i|
        desc = (uc.desc || "Usecase ##{i+1}")
        Stella.li ' %-65s '.att(:reverse).bright % [desc]
        Stella.rescue { client.execute uc }
        #benelux_timeline += client.http_client.benelux_timeline
      end
      
      # Add client timeline only once (it's okay we sort later)
      benelux_timeline += client.benelux_timeline
      
      p benelux_timeline.sort.to_line
      
      #p client.benelux_at(:execute_start).first.name
      
      #p client.benelux_between(:execute_start, :execute_end)
      
      #p client.benelux_duration(:execute)
      
      !plan.errors?
    end
    
    
    def update_prepare_request(client_id, usecase, req, counter)
      notice = "repeat: #{counter-1}" if counter > 1
      Stella.li2 ' ' << " %-46s %16s ".att(:reverse) % [req.desc, notice]
    end
    
    def update_send_request(client_id, usecase, uri, req, params, counter)

    end
    
    def update_receive_response(client_id, usecase, uri, req, params, container)
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
      Stella.ld ex.backtrace
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

