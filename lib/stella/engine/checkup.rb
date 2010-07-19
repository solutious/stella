
module Stella::Engine
  class Checkup < Stella::Engine::Base
    
    def run(testrun)
      client = Stella::Client.new testrun.hosts.first, testrun.client_options
      client.add_observer(self)
      
      p testrun.client_options
      
      Stella.stdout.info2 $/, "Starting test...", $/
      testrun.start_time = Time.now.utc.to_i
      
      start_time = Time.now.utc
      
      thread = Thread.new do
        # Identify this thread to Benelux
        Benelux.current_track :functional
        
        dig = Stella.stdout.lev > 1 ? testrun.plan.id : testrun.plan.id.shorter
        Stella.stdout.info " %-65s  ".att(:reverse) % ["#{testrun.plan.desc}  (#{dig})"]
        testrun.plan.usecases.each_with_index do |uc,i|
          desc = (uc.desc || "Usecase ##{i+1}")
          Benelux.add_thread_tags :usecase => uc.id
          dig = Stella.stdout.lev > 1 ? uc.id : uc.id.shorter
          Stella.stdout.info ' %-65s '.att(:reverse).bright % ["#{desc}  (#{dig}) "]
          Stella.rescue { client.execute uc }
        end
      end
      
      thread.join
      
      test_time = Time.now.utc - start_time
      
      # Need to use thread timeline b/c the clients are running in the
      # main thread which Benelux.update_global_timeline does not touch.
      tt = thread.timeline
      
      testrun
    end
    
    
    def update_prepare_request(client_id, usecase, req, counter)
      notice = "repeat: #{counter-1}" if counter > 1
      dig = Stella.stdout.lev > 1 ? req.id : req.id.shorter
      desc = "#{req.desc}  (#{dig}) "
      Stella.stdout.info2 "  %-46s %16s ".bright % [desc, notice]
    end
    
    
    def update_receive_response(client_id, usecase, uri, req, params, headers, counter, container)
      log = Stella::Engine::Log.new Time.now.to_f, container.unique_id, client_id,
                                    'testplanid',
                                    usecase.id, req.id,
                                    req.http_method, container.status, uri.to_s,
                                    params, container.response.request.header.dump, 
                                    container.response.header.dump, 
                                    container.response.body.content
      
      Benelux.thread_timeline.add_message log, :status => container.status, :kind => :log
      
      msg = '  %-6s %-53s ' % [req.http_method, uri]
      msg << container.status.to_s if Stella.stdout.lev <= 2
      Stella.stdout.info msg
      
      Stella.stdout.info2 $/, "   Params:"
      params.each do |pair|
        Stella.stdout.info2 "     %s: %s" % pair
      end
      
      Stella.stdout.info3 $/, '   ' << container.response.request.header.send(:request_line)
      
      container.response.request.header.all.each do |pair|
        Stella.stdout.info3 "   %s: %s" % pair
      end
      
      if req.http_method == 'POST'
        cont = container.response.request.body.content
        if String === cont
          Stella.stdout.info4('   ' << cont.split($/).join("#{$/}    "))
        elsif HTTP::Message::Body::Parts === cont
          cont.parts.each do |part|
            if File === part
              Stella.stdout.info4 "<#{part.path}>"
            else
              Stella.stdout.info4 part
            end
          end
        end
      end
      
      resh = container.response.header
      Stella.stdout.info3 $/, '   HTTP/%s %3d %s' % [resh.http_version, resh.status_code, resh.reason_phrase]
      container.headers.all.each do |pair|
        Stella.stdout.info3 "   %s: %s" % pair
      end
      Stella.stdout.info4 container.body.empty? ? '   [empty]' : container.body
      Stella.stdout.info2 $/
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
      Stella.le "#{ex.message} (#{ex.backtrace.first})"
      Stella.ld ex.backtrace
    end
    
    def update_request_unhandled_exception(client_id, usecase, uri, req, params, ex)
      #desc = "#{usecase.desc} > #{req.desc}"
      Stella.le '  ERROR   %24s   %s' % [ex.message, uri]
      Stella.le '  %s' % params.inspect
      unless req.headers.nil? || req.headers.empty? 
        Stella.le '  %s' % req.headers.inspect
      end
      Stella.ld ex.backtrace
    end
    
    def update_follow_redirect client_id, ret, req, container
      Stella.stdout.info2 "  FOLLOW   %-53s" % [ret.uri]
    end
    
    def update_max_redirects client_id, counter, ret, req, container
      Stella.stdout.info "  MAX REDIRECTS   %-53s" % [counter]
    end
    
    def update_usecase_quit client_id, msg, req, container
      Benelux.thread_timeline.add_count :failed, 1
      Stella.stdout.info "  QUIT   %s" % [msg]
    end
    
    def update_request_fail client_id, msg, req, container
      Benelux.thread_timeline.add_count :failed, 1
      Stella.stdout.info "  FAILED   %s" % [msg]
    end
    
    def update_request_error client_id, msg, req, container
      Benelux.thread_timeline.add_count :failed, 1
      Stella.stdout.info "  ERROR   %s" % [msg]
    end
    
    def update_request_repeat client_id, counter, total, req, container
      Stella.stdout.info3 "  REPEAT   %d of %d" % [counter, total]
    end
    
    def update_authenticate client_id, usecase, req, domain, user, pass
      Stella.stdout.info "  AUTH   #{domain} (#{user}/#{pass})"
    end
    
    def update_request_timeout(client_id, usecase, uri, req, params, headers, counter, container, timeout)
      Benelux.thread_timeline.add_count :failed, 1
      Stella.stdout.info "  TIMEOUT(%f)   %-53s" % [uri, timeout]
    end
    
  end
end
