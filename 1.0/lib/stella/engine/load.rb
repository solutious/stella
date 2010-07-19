
module Stella::Engine
  class Load < Stella::Engine::Base
    
    @timers = [:response_time]
    @counts = [:response_content_size]
    
    def run(testrun)
      @threads, @max_clients, @real_reps = [], 0, 0
      counts = calculate_usecase_clients testrun
      packages = build_thread_package testrun, counts
      
      unless Stella::Logger.disabled?
        Stella.stdout.info "Logging to #{testrun.log_dir}", $/

        latest = File.join(File.dirname(testrun.log_dir), 'latest')
        if Stella.sysinfo.os == :unix
          File.unlink latest if File.exists? latest
          FileUtils.ln_sf File.basename(testrun.log_dir), latest
        end
      end
      
      @sumlog = Stella::Logger.new testrun.log_path('summary')
      @failog = Stella::Logger.new testrun.log_path('exceptions')
      
      Stella.stdout.add_template :head, '  %s: %s'
      Stella.stdout.add_template :status,  "#{$/}%s..."
      
      if Stella.stdout.lev >= 2
        Load.timers += [:socket_connect, :send_request, :first_byte, :receive_response]
        Load.counts  = [:request_header_size, :request_content_size]
        Load.counts += [:response_headers_size, :response_content_size]
      end

      testrun.save
      
      @dumper = prepare_dumper(testrun)
      
      if testrun.duration > 0
        timing = "#{testrun.duration.seconds.to_i} seconds"
      else
        timing = "#{testrun.repetitions} repetitions"
      end
      
      Stella.stdout.head "Runid", "#{testrun.id.shorter}"
      Stella.stdout.head 'Plan', "#{testrun.plan.desc} (#{testrun.plan.id.shorter})"
      Stella.stdout.head 'Hosts', testrun.hosts.join(', ')
      Stella.stdout.head 'Clients', counts[:total]
      Stella.stdout.head 'Limit', timing
      Stella.stdout.head 'Wait', testrun.wait
      Stella.stdout.head 'Arrival', testrun.arrival if testrun.arrival
      
      @dumper.start
      
      begin 
        Stella.stdout.status "Running" 
        testrun.status = "running"
        testrun.start_time = Time.now.utc.to_i
        execute_test_plan packages, testrun
      rescue Interrupt
        Stella.stdout.info $/, "Stopping test"
        Stella.abort!
        @threads.each { |t| t.join } unless @threads.nil? || @threads.empty? # wait
      rescue => ex
        STDERR.puts "Unhandled exception: #{ex.message}"
        STDERR.puts ex.backtrace if Stella.debug? || Stella.stdout.lev >= 3
      end
      
      Stella.stdout.status "Processing"
      
      @dumper.stop
      
      bt = Benelux.timeline
      tt = Benelux.thread_timeline
      
      # TODO: don't get test time from benelux. 
      test_time = tt.stats.group(:execute_test_plan).mean
      generate_report @sumlog, testrun, test_time
      #report_time = tt.stats.group(:generate_report).mean
      
      unless Stella::Logger.disabled?
        Stella.stdout.info File.read(@sumlog.path)
        Stella.stdout.info $/, "Log dir: #{testrun.log_dir}"
      end
      
      testrun
    end
    
    def execute_test_plan(packages, testrun)
      time_started = Time.now
      
      pqueue = Queue.new
      packages.each { |p| pqueue << p  }
      
      @real_reps += 1  # Increments when duration is specified.
      @threads = []
      packages.size.times {
        @max_clients += 1
        @threads << Thread.new do
          package = pqueue.pop
          Thread.current[:real_reps] = 0
          Thread.current[:real_uctime] = Benelux::Stats::Calculator.new
          c, uc = package.client, package.usecase
          Stella.stdout.info4 $/, "======== THREAD %s: START" % [c.id.short]  

          # This thread will stay on this one track. 
          Benelux.current_track c.id
          
          Benelux.add_thread_tags :usecase => uc.id
          Thread.current[:real_uctime].first_tick
          prev_ptime ||= Time.now
          testrun.repetitions.times { |rep| 
            break if Stella.abort?
            Thread.current[:real_reps] += 1
            # NOTE: It's important to not call digest or gibbler methods
            # on client object b/c it is not frozen. Always use digest_cache.
            args = [c.id.short, uc.desc, uc.id.short, Thread.current[:real_reps]]
            Stella.stdout.info4 $/, "======== THREAD %s: %s:%s (rep: %d)" % args
            
            Benelux.add_thread_tags :rep =>  rep
            #Stella.stdout.info [package.client.gibbler.shorter, package.usecase.gibbler.shorter, rep].inspect
            Stella::Engine::Load.rescue(c.id) {
              break if Stella.abort?
              print '.' if Stella.stdout.lev == 2
              stats = c.execute uc
            }
            Benelux.remove_thread_tags :rep
            
            Thread.current[:real_uctime].tick
            time_elapsed = (Time.now - time_started).to_i
            
            if (Time.now - prev_ptime).to_i >= testrun.granularity
              prev_ptime, ruct = Time.now, Thread.current[:real_uctime]
              if Stella.stdout.lev >= 2 && Thread.current == @threads.first 
                args = [time_elapsed.to_i, ruct.n, ruct.mean, ruct.sd]
                Stella.stdout.info2 $/, "REAL UC TIME: %ds (reps: %d): %.4fs %.4f(SD)" % args
              end
              
              Thread.current.rotate_timeline
            end
            
            # If a duration was given, we make sure 
            # to run for only that amount of time.
            if testrun.duration > 0
              break if (time_elapsed+Thread.current[:real_uctime].mean) >= testrun.duration
              redo if (time_elapsed+Thread.current[:real_uctime].mean) <= testrun.duration
            end
          }
          
          Benelux.remove_thread_tags :usecase
          
          pqueue << package  # return the package to the queue
        end

        #p [testrun.arrival, 1/testrun.arrival]
        
        unless testrun.arrival.nil? || testrun.arrival.to_f <= 0
          # Create 1 second / users per second 
          args = [@threads.size, packages.size]
          Stella.stdout.print 2, '+'
          Stella.stdout.info3 $/, "-> NEW CLIENT: %s of %s" % args
          sleep 1/testrun.arrival
        end
        
      }
      
      repscalc = Benelux::Stats::Calculator.new
      @threads.each { |t| t.join } # wait
      @threads.each { |t| repscalc.sample(t[:real_reps]) }
      @real_reps = repscalc.mean.to_i
      
      
      #Stella.stdout.info "*** REPETITION #{@real_reps} of #{reps} ***"
      
      Stella.stdout.info2 $/, $/
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
    
    def prepare_dumper(testrun)
      hand = Stella::Hand.new(testrun.granularity, 2.seconds) do
        Benelux.update_global_timeline 
        # @threads contains only stella clients
        concurrency = @threads.select { |t| !t.status.nil? }.size
        batch, timeline = Benelux.timeline_updates, Benelux.timeline_chunk
        testrun.add_sample batch, concurrency, timeline
        testrun.log = [] unless testrun.has_log?
        if testrun.log.size < testrun.logsize
          tmp = Benelux.timeline.messages.filter(:kind => :log)
          unless tmp.nil? || tmp.empty?
            # grab only as many elements from the log as configured
            testrun.log.push *tmp.first(testrun.logsize-testrun.log.size) 
          end
        end
        testrun.save
        @failog.info Benelux.timeline.messages.filter(:kind => :exception)
        @failog.info Benelux.timeline.messages.filter(:kind => :timeout)
        Benelux.timeline.clear if testrun.nostats
      end
      hand.finally do
        testrun.end_time = Time.now.utc.to_i
        testrun.save
      end
      hand
    end

    def generate_report(sumlog,testrun,test_time)
      global_timeline = Benelux.timeline
      global_stats = global_timeline.stats.group(:response_time).merge
      if global_stats.n == 0
        Stella.ld "No stats"
        return
      end
      
      @sumlog.info " %-72s  ".att(:reverse) % ["#{testrun.plan.desc}  (#{testrun.plan.id.shorter})"]
      testrun.plan.usecases.uniq.each_with_index do |uc,i| 
        
        # TODO: Create Ranges object, like Stats object
        # global_timeline.ranges(:response_time)[:usecase => '1111']
        # The following returns global response_time ranges. 
        requests = 0 #global_timeline.ranges(:response_time).size
        
        desc = uc.desc || "Usecase ##{i+1} "
        desc << "  (#{uc.id.shorter}) "
        str = ' ' << " %-66s %s   %d%% ".bright.att(:reverse)
        @sumlog.info str % [desc, '', uc.ratio_pretty]        
        uc.requests.each do |req| 
          filter = [uc.id, req.id]
          desc = req.desc 
          @sumlog.info "   %-72s ".bright % ["#{req.desc}  (#{req.id.shorter})"]
          @sumlog.info "    %s" % [req.to_s]

          Load.timers.each do |sname|
            stats = global_timeline.stats.group(sname)[filter].merge
#            Stella.stdout.info stats.inspect
            str = '      %-30s %.3f <= ' << '%.3fs' << ' >= %.3f; %.3f(SD) %d(N)'
            msg = str % [sname, stats.min, stats.mean, stats.max, stats.sd, stats.n]
            @sumlog.info msg
            @sumlog.flush
          end
          @sumlog.info $/
        end
        
        @sumlog.info "   Sub Total:".bright
        
        stats = global_timeline.stats.group(:response_time)[uc.id].merge
        failed = global_timeline.stats.group(:failed)[uc.id].merge
        respgrp = global_timeline.stats.group(:execute_response_handler)[uc.id]
        resst = respgrp.tag_values(:status)
        
        Load.timers.each do |sname|
          stats = global_timeline.stats.group(sname)[uc.id].merge
          @sumlog.info '      %-30s %.3fs %.3f(SD)' % [sname, stats.mean, stats.sd]
          @sumlog.flush
        end
        
        Load.counts.each do |sname|
          stats = global_timeline.stats.group(sname)[uc.id].merge
          @sumlog.info '      %-30s %-12s (avg:%s)' % [sname, stats.sum.to_bytes, stats.mean.to_bytes]
          @sumlog.flush
        end
        @sumlog.info $/
        statusi = []
        resst.each do |status|
          size = respgrp[:status => status].size
          statusi << "#{status}: #{size}"
        end
        @sumlog.info '      %-30s %d (%s)' % ['Total requests', stats.n, statusi.join(', ')]
        @sumlog.info '       %-29s %d' % [:success, stats.n - failed.n]
        @sumlog.info '       %-29s %d' % [:failed, failed.n]
        
        @sumlog.info $/
      end
      
      @sumlog.info ' ' << " %-66s ".att(:reverse) % 'Total:'
      @sumlog.flush
      
      failed = global_timeline.stats.group(:failed)
      respgrp = global_timeline.stats.group(:execute_response_handler)
      resst = respgrp.tag_values(:status)
      statusi = []
      resst.each do |status|
        size = respgrp[:status => status].size
        statusi << [status, size]
      end
     
      Load.timers.each do |sname|
        stats = global_timeline.stats.group(sname).merge
        @sumlog.info '      %-30s %-.3fs     %-.3f(SD)' % [sname, stats.mean, stats.sd]
        @sumlog.flush
      end
      
      Load.counts.each do |sname|
        stats = global_timeline.stats.group(sname).merge
        @sumlog.info '      %-30s %-12s (avg:%s)' % [sname, stats.sum.to_bytes, stats.mean.to_bytes]
        @sumlog.flush
      end
      
      @sumlog.info $/
      @sumlog.info  '      %-30s %d' % ['Total requests', global_stats.n]
      
      success = global_stats.n - failed.n
      @sumlog.info  '       %-29s %d (req/s: %.2f)' % [:success, success, success/test_time]
      statusi.each do |pair|
        @sumlog.info3 '        %-28s %s: %d' % ['', *pair]
      end
      @sumlog.info  '       %-29s %d' % [:failed, failed.n]
      
      @sumlog.flush
      
    end
    
    
    def calculate_usecase_clients(testrun)
      counts = { :total => 0 }
      testrun.plan.usecases.each_with_index do |usecase,i|
        count = case testrun.clients
        when 0..9
          if (testrun.clients % testrun.plan.usecases.size > 0) 
            msg = "Client count (%d) does not evenly match usecase count (%d)"
            raise Stella::WackyRatio, (msg % [testrun.clients, testrun.plan.usecases.size])
          else
            (testrun.clients / testrun.plan.usecases.size)
          end
        else
          (testrun.clients * usecase.ratio).to_i
        end
        counts[usecase.id] = count
        counts[:total] += count
      end
      counts
    end

    
    def build_thread_package(testrun, counts)
      packages, pointer = Array.new(counts[:total]), 0
      testrun.plan.usecases.each do |usecase|
        count = counts[usecase.id]
        Stella.ld "THREAD PACKAGE: #{usecase.desc} (#{pointer} + #{count})"
        # Fill the thread_package with the contents of the block
        packages.fill(pointer, count) do |index|
          client = Stella::Client.new testrun.hosts.first, testrun.client_options
          client.add_observer(self)
          Stella.stdout.info4 "Created client #{client.id.short}"
          ThreadPackage.new(index+1, client, usecase)
        end
        pointer += count
      end
      packages.compact # TODO: Why one nil element sometimes?
      # Randomize so when ramping up load
      # we get a mix of usecases. 
      packages.sort_by {rand}
    end
    
    
    def running_threads
      @threads.select { |t| t.status }  # non-false status are still running
    end
    
    def generate_runtime_report(testrun)
      gt = Benelux.timeline
      gstats = gt.stats.group(:response_time).merge
      
      testrun.plan.usecases.uniq.each_with_index do |uc,i| 
        uc.requests.each do |req| 
          filter = [uc.id, req.id]

          Load.timers.each do |sname|
            stats = gt.stats.group(sname)[filter].merge
            #Stella.stdout.info stats.inspect
            puts [sname, stats.min, stats.mean, stats.max, stats.sd, stats.n].join('; ')
          end
          
        end
      end
      
    end
    
    def update_prepare_request(client_id, usecase, req, counter)
     
    end
    
    def update_receive_response(client_id, usecase, uri, req, params, headers, counter, container)
      if @opts[:with_content]
        log = Stella::Engine::Log.new Time.now.to_f, container.unique_id, client_id,
                                      'testplanid',
                                      usecase.id, req.id,
                                      req.http_method, container.status, uri.to_s,
                                      params, container.response.request.header.dump, 
                                      container.response.header.dump, 
                                      container.response.body.dump

        # Fix for no data, but why??
        log.response_body = container.response.body.dump
        Benelux.thread_timeline.add_message log, :status => container.status, :kind => :log
      end
      
      args = [Time.now.to_f, Stella.sysinfo.hostname, client_id.short]
      args.push usecase.id.shorter, req.id.shorter
      args.push req.http_method, container.status, uri
      args << params.to_a.collect { |el| 
        next if el[0].to_s == '__stella'
        '%s=%s' % [el[0], el[1].to_s] 
      }.compact.join('&') # remove skipped params
      args << headers.to_a.collect { |el|
        next if el[0].to_s == 'X-Stella-ID'
        '%s=%s' % el 
      }.compact.join('&') # remove skipped params
      args << container.unique_id[0,10]
      #Benelux.thread_timeline.add_message args.join('; '), 
      # :status => container.status,
      # :kind => :request
      args = [client_id.shorter, container.status, req.http_method, uri, params.inspect]
      Stella.stdout.info3 '  Client-%s %3d %-6s %s %s' % args
            
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
      Benelux.thread_timeline.add_message ex.message, :kind => :exception
      Benelux.thread_timeline.add_count :exception, 1
      desc = "#{container.usecase.desc} > #{req.desc}"
      if Stella.stdout.lev == 2
        Stella.stdout.print 2, '.'.color(:red)
      else
        Stella.le '  Client-%s %-45s %s' % [client_id.shorter, desc, ex.message]
        Stella.ld ex.backtrace
      end
    end
    
    def update_request_unhandled_exception(client_id, usecase, uri, req, params, ex)
      Benelux.thread_timeline.add_message ex.message, :kind => :exception
      Benelux.thread_timeline.add_count :exception, 1
      desc = "#{usecase.desc} > #{req.desc}"
      if Stella.stdout.lev == 2
        Stella.stdout.print 2, '.'.color(:red)
      else
        Stella.le '  Client-%s %-45s %s' % [client_id.shorter, desc, ex.message]
        Stella.ld ex.backtrace
      end
    end
    
    def update_usecase_quit client_id, msg, req, container
      Benelux.thread_timeline.add_count :quit, 1
      Benelux.thread_timeline.add_message msg, :kind => :quit
      Stella.stdout.info3 "  Client-%s     QUIT   %s" % [client_id.shorter, msg]
    end
    
    def update_request_fail client_id, msg, req, container
      Benelux.thread_timeline.add_count :failed, 1
      Benelux.thread_timeline.add_message msg, :kind => :fail
      Stella.stdout.info3 "  Client-%s     FAILED   %s" % [client_id.shorter, msg]
    end
    
    def update_request_error client_id, msg, req, container
      args = [Time.now.to_f, Stella.sysinfo.hostname, client_id.short]
      Benelux.thread_timeline.add_count :exception, 1
      Benelux.thread_timeline.add_message msg, :kind => :exception
      if Stella.stdout.lev >= 3
        Stella.le '  Client-%s %s' % [client_id.shorter, ex.message]
      end
    end
      
    def update_request_repeat client_id, counter, total, req, container
      Stella.stdout.info3 "  Client-%s     REPEAT   %d of %d" % [client_id.shorter, counter, total]
    end
    
    def update_follow_redirect client_id, ret, req, container
      Stella.stdout.info3 "  Client-%s     FOLLOW   %-53s" % [client_id.shorter, ret.uri]
    end
    
    def update_max_redirects client_id, counter, ret, req, container
      Stella.stdout.info3 "  Client-%s     MAX REDIRECTS   %s " % [client_id.shorter, counter]
    end
    
    def update_authenticate client_id, usecase, req, domain, user, pass
      args = [Time.now.to_f, Stella.sysinfo.hostname, client_id.short]
      args.push usecase.id.shorter, req.id.shorter
      args.push 'AUTH', domain, user, pass
      Benelux.thread_timeline.add_message args.join('; '), :kind => :authentication
    end
    
    def update_request_timeout(client_id, usecase, uri, req, params, headers, counter, container, timeout)
      msg = "  Client-%s     TIMEOUT(%.1f)   %-53s" % [client_id.shorter, timeout, uri]
      Stella.stdout.info3 msg
      Benelux.thread_timeline.add_count :exception, 1
      args = [Time.now.to_f, Stella.sysinfo.hostname, client_id.short]
      args.push [uri, 'TOUT', container.unique_id[0,10]]
      Benelux.thread_timeline.add_message msg , :kind => :exception
    end
    
    def self.rescue(client_id, &blk)
      blk.call
    rescue => ex
      Stella.le '  Error in Client-%s: %s' % [client_id.shorter, ex.message]
      Stella.ld ex.backtrace
    end
    
    Benelux.add_timer Stella::Engine::Load, :build_thread_package
    Benelux.add_timer Stella::Engine::Load, :generate_report
    Benelux.add_timer Stella::Engine::Load, :execute_test_plan
        
  end
end

