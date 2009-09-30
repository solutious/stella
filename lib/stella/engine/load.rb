
module Stella::Engine
  module Load
    extend Stella::Engine::Base
    extend self
      
    def run(plan, opts={})
      opts = {
        :hosts        => [],
        :clients        => 1,
        :time         => nil,
        :nowait    => false,
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

        Benelux.current_track package.client.gibbler
        Benelux.add_thread_tags :usecase => package.usecase.gibbler_cache
        
        (1..opts[:repetitions]).to_a.each do |rep|
          
          Benelux.add_thread_tags :rep =>  rep
          
          # We store client specific data in the usecase
          # so we clone it here so each thread is unique.
          Stella::Engine::Load.rescue(package.client.gibbler_cache) { 
            stats = package.client.execute package.usecase
          }
          
          Benelux.remove_thread_tags :rep
          
          Benelux.update_track_timeline
          
        end
        
        Benelux.remove_thread_tags :usecase
      
      end
      
      generate_report(plan)
      
      # This will contain only the one call to generate_report
      rep_stats = self.timeline.ranges.first
      
      Stella.li "Reporting time: %0.4f" % [rep_stats.duration]
      
      !plan.errors?
    end
    
    def generate_report(plan)
      Stella.li $/, " %-68s %s  ".att(:reverse) % [plan.desc, plan.gibbler_cache.shorter]
      plan.usecases.uniq.each_with_index do |uc,i| 
        description = uc.desc || "Usecase ##{i+1}"
        str = ' ' << " %-50s  %22s ".bright.att(:reverse) << ' (%s%%)'.bright
        Stella.li str % [description, uc.gibbler_cache.shorter, uc.ratio_pretty]
        uc.requests.each do |req| 
          Stella.li "   %-66s %s ".bright % [req.desc, req.gibbler_cache.shorter]
          Stella.li "    %s" % [req.to_s]
          Benelux.timeline.stats.each_pair do |n,stat|
            filter = {
              :usecase => uc.gibbler_cache,
              :request => req.gibbler_cache
            }
            stats = stat[filter]
            Stella.li '      %-30s %.3f <= %.3f >= %.3f; %.3f(SD) %d(N)' % [n, stats.min, stats.mean, stats.max, stats.sd, stats.n]
          end
          Stella.li $/
          #if Stella.loglev > 2
          #  [:wait].each { |i| str << "      %s: %s" % [i, r.send(i)] }
          #end
        end
      end
    end
  
    Benelux.add_timer Stella::Engine::Load, :generate_report
  
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
          Stella.li3 "Creating client ##{index+1} "
          client = Stella::Client.new opts[:hosts].first, index+1
          client.add_observer(self)
          client.enable_nowait_mode if opts[:nowait]
          ThreadPackage.new(index+1, client, usecase)
        end
        pointer += count
      end
      packages.compact # TODO: Why one nil element sometimes?
    end
      
      
    def update_prepare_request(client_id, usecase, req, counter)
      
    end
      
    def update_send_request(client_id, usecase, uri, req, params, headers, counter)
      
    end
      
    def update_receive_response(client_id, usecase, uri, req, params, headers, container)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.li2 '  Client-%s %3d %-6s %-45s' % [client_id.shorter, container.status, req.http_method, uri]
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
    end
    
    def update_request_error(client_id, usecase, uri, req, params, ex)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.le '  Client-%s %-45s %s' % [client_id.shorter, desc, ex.message]
      Stella.ld ex.backtrace
    end

    
    def self.rescue(client_id, &blk)
      blk.call
    rescue => ex
      Stella.le '  Error in Client-%s: %s' % [client_id.shorter, ex.message]
      Stella.ld ex.backtrace
    end
    
  end
end

__END__


$ stella verify -p examples/basic/plan.rb http://localhost:3114
$ stella load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-verify -p examples/basic/plan.rb http://localhost:3114

