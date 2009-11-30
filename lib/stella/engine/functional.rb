
module Stella::Engine
  module Functional
    extend Stella::Engine::Base
    extend self
    
    def run(plan, opts={})
      opts = process_options! plan, opts
      
      Stella.ld "OPTIONS: #{opts.inspect}"
      Stella.stdout.info2 "Hosts: " << opts[:hosts].join(', ') if !opts[:hosts].empty?
      
      client = Stella::Client.new opts[:hosts].first, 1, opts
      client.add_observer(self)

      client.enable_nowait_mode if opts[:nowait]
      
      Stella.stdout.info2 $/, "Starting test...", $/
      sleep 0.3
      
      # Identify this thread to Benelux
      Benelux.current_track :functional 
      
      dig = Stella.stdout.lev > 1 ? plan.digest_cache : plan.digest_cache.shorter
      Stella.stdout.info " %-65s  ".att(:reverse) % ["#{plan.desc}  (#{dig})"]
      plan.usecases.each_with_index do |uc,i|
        desc = (uc.desc || "Usecase ##{i+1}")
        dig = Stella.stdout.lev > 1 ? uc.digest_cache : uc.digest_cache.shorter
        Stella.stdout.info ' %-65s '.att(:reverse).bright % ["#{desc}  (#{dig}) "]
        Stella.rescue { client.execute uc }
      end
      
      tl = Benelux.thread_timeline
      tl.stats.group(:failed).merge.n == 0
    end
    
    
    def update_prepare_request(client_id, usecase, req, counter)
      notice = "repeat: #{counter-1}" if counter > 1
      dig = Stella.stdout.lev > 1 ? req.digest_cache : req.digest_cache.shorter
      desc = "#{req.desc}  (#{dig}) "
      Stella.stdout.info2 "  %-46s %16s ".bright % [desc, notice]
    end
    
    def update_receive_response(client_id, usecase, uri, req, params, headers, counter, container)
      msg = '  %-6s %-53s ' % [req.http_method, uri]
      msg << container.status.to_s if Stella.stdout.lev == 1
      Stella.stdout.info msg
      
      Stella.stdout.info2 $/, "   Params:"
      params.each do |pair|
        Stella.stdout.info2 "     %s: %s" % pair
      end
      
      Stella.stdout.info2 $/, '   ' << container.response.request.header.send(:request_line)
      
      container.response.request.header.all.each do |pair|
        Stella.stdout.info2 "   %s: %s" % pair
      end
      
      if req.http_method == 'POST'
        cont = container.response.request.body.content
        if String === cont
          Stella.stdout.info3 ('   ' << cont.split($/).join("#{$/}    "))
        elsif HTTP::Message::Body::Parts === cont
          cont.parts.each do |part|
            if File === part
              Stella.stdout.info3 "<#{part.path}>"
            else
              Stella.stdout.info3 part
            end
          end
        end
      end
      
      resh = container.response.header
      Stella.stdout.info2 $/, '   HTTP/%s %3d %s' % [resh.http_version, resh.status_code, resh.reason_phrase]
      container.headers.all.each do |pair|
        Stella.stdout.info2 "   %s: %s" % pair
      end
      Stella.stdout.info3 container.body.empty? ? '   [empty]' : container.body
      Stella.stdout.info2 $/
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
      Stella.le ex.message
      Stella.ld ex.backtrace
    end
    
    def update_request_unhandled_exception(client_id, usecase, uri, req, params, ex)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.le '  Client-%s %-45s %s' % [client_id.short, desc, ex.message]
      Stella.ld ex.backtrace
    end
    
    def update_usecase_quit client_id, msg, req, container
      Stella.stdout.info "  QUIT   %s" % [msg]
    end
    
    def update_request_fail client_id, msg, req, container
      Benelux.thread_timeline.add_count :failed, 1
      Stella.stdout.info "  FAILED   %s" % [msg]
    end
    
    def update_request_error client_id, msg, req, container
      Stella.stdout.info "  ERROR   %s" % [msg]
    end
    
    def update_request_repeat client_id, counter, total, req, container
      Stella.stdout.info3 "  Client-%s     REPEAT   %d of %d" % [client_id.shorter, counter, total]
    end
    
    def update_authenticate client_id, usecase, req, kind, domain, user, pass
      Stella.stdout.info "  AUTH   (#{kind}) #{domain} (#{user}/#{pass})"
    end
  end
end

__END__


$ stella verify -p examples/basic/plan.rb http://localhost:3114
$ stella load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-verify -p examples/basic/plan.rb http://localhost:3114

