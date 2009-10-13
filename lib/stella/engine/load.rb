
module Stella::Engine
  module Load
    extend Stella::Engine::Base
    extend self
    
    @timers = [:do_request]
    @counts = [:response_content_size]
    
    class << self
      attr_accessor :timers, :counts
    end
    
    def run(plan, opts={})
      opts = process_options! plan, opts
      @threads, @max_clients, @real_reps = [], 0, 0
      
      if Stella.loglev > 1
        Load.timers += [:connect, :create_socket, :query, :socket_gets_first_byte, :get_body]
        Load.counts  = [:request_header_size, :request_content_size]
        Load.counts += [:response_headers_size, :response_content_size]
      end
      
      counts = calculate_usecase_clients plan, opts
      
      Stella.li $/, "Preparing #{counts[:total]} virtual clients...", $/
      Stella.lflush
      packages = build_thread_package plan, opts, counts
      
      if opts[:duration] > 0
        msg = "for #{opts[:duration].seconds}s"
      else
        msg = "for #{opts[:repetitions]} reps"
      end
      
      Stella.li "Generating requests #{msg}...", $/
      Stella.lflush
      
      @mode = :rolling
      
      begin
        execute_test_plan packages, opts[:repetitions], opts[:duration]
      rescue Interrupt
        Stella.li "Stopping test...", $/
        Stella.abort!
      ensure
        Stella.li "Processing statistics...", $/
        Stella.lflush
        
        wait_for_reporter
        
        tt = Benelux.thread_timeline
        test_time = tt.stats.group(:execute_test_plan).mean
        
        generate_report plan, test_time
        
        #p Benelux.timeline
        
        Stella.li "Summary: "
        Stella.li "  max clients: %d" % @max_clients
        Stella.li "  repetitions: %d" % @real_reps
        Stella.li "    test time: %10.2fs" % test_time
        Stella.li "    wait time: %10.2fs" % tt.stats.group(:wait_for_reporter).mean
        Stella.li "    post time: %10.2fs" % tt.stats.group(:generate_report).mean
        Stella.li $/
      end
      
      # errors?
    end
    
    def wait_for_reporter
      Benelux.reporter.force_update
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
    
    def calculate_usecase_clients(plan, opts)
      counts = { :total => 0 }
      plan.usecases.each_with_index do |usecase,i|
        count = case opts[:clients]
        when 0..9
          if (opts[:clients] % plan.usecases.size > 0) 
            msg = "Client count does not evenly match usecase count"
            raise Stella::WackyRatio, msg
          else
            (opts[:clients] / plan.usecases.size)
          end
        else
          (opts[:clients] * usecase.ratio).to_i
        end
        counts[usecase.digest_cache] = count
        counts[:total] += count
      end
      counts
    end
    
    def build_thread_package(plan, opts, counts)
      packages, pointer = Array.new(counts[:total]), 0
      plan.usecases.each do |usecase|
        count = counts[usecase.digest_cache]
        Stella.ld "THREAD PACKAGE: #{usecase.desc} (#{pointer} + #{count})"
        # Fill the thread_package with the contents of the block
        packages.fill(pointer, count) do |index|
          client = Stella::Client.new opts[:hosts].first, index+1
          client.add_observer(self)
          client.enable_nowait_mode if opts[:nowait]
          Stella.li4 "Created client #{client.digest.short}"
          ThreadPackage.new(index+1, client, usecase)
        end
        pointer += count
      end
      packages.compact # TODO: Why one nil element sometimes?
    end
    
    def execute_test_plan(packages, reps=1, duration=0)
      time_started = Time.now

      (1..reps).to_a.each { |rep|
        @real_reps += 1  # Increments when duration is specified.
        Stella.li3 "*** REPETITION #{@real_reps} of #{reps} ***"
        packages.each { |package|
          if running_threads.size <= packages.size
            @threads << Thread.new do
              c, uc = package.client, package.usecase
              msg = "THREAD START: client %s: " % [c.digest.short] 
              msg << "%s:%s (rep: %d)" % [uc.desc, uc.digest.short, @real_reps]
              Stella.li4 $/, "======== " << msg
              # This thread will stay on this one track. 
              Benelux.current_track c.digest
              Benelux.add_thread_tags :usecase => uc.digest_cache
          
              Benelux.add_thread_tags :rep =>  @real_reps
              Stella::Engine::Load.rescue(c.digest_cache) {
                break if Stella.abort?
                print '.' if Stella.loglev == 2
                stats = c.execute uc
              }
              Benelux.remove_thread_tags :rep
              Benelux.remove_thread_tags :usecase
            
            end
            Stella.sleep :create_thread
          end
          
          if running_threads.size > @max_clients
            @max_clients = running_threads.size
          end
          
          if @mode == :rolling
            tries = 0
            while (reps > 1 || duration > 0) && running_threads.size >= packages.size
              Stella.sleep :check_threads
              msg = "#{running_threads.size} (max: #{@max_clients})"
              Stella.li3 "*** RUNNING THREADS: #{msg} ***"
              (tries += 1)
            end
          end
        }
        
        if @mode != :rolling && running_threads.size > 0
          args = [running_threads.size, @max_clients]
          Stella.li3 "*** WAITING FOR %d THREADS TO FINISH (max: %d) ***" % args
          @threads.each { |t| t.join } # wait
        end
        
        # If a duration was given, we make sure 
        # to run for only that amount of time.
        # TODO: do not redo if 
        # time_elapsed + usecase.mean > duration
        if duration > 0
          time_elapsed = (Time.now - time_started).to_i
          msg = "#{time_elapsed} of #{duration} (threads: %d)" % running_threads.size
          Stella.li3 "*** TIME ELAPSED: #{msg} ***"
          redo if time_elapsed <= duration 
          break if time_elapsed >= duration
        end

      }
      
      if @mode == :rolling && running_threads.size > 0
        Stella.li3 "*** WAITING FOR THREADS TO FINISH ***"
        @threads.each { |t| t.join } # wait
      end
      Stella.li2 $/, $/
    end
    def running_threads
      @threads.select { |t| t.status }  # non-false status are still running
    end
    def generate_report(plan,test_time)
      #Benelux.update_all_track_timelines
      global_timeline = Benelux.timeline
      
      Stella.li $/, " %-72s  ".att(:reverse) % ["#{plan.desc}  (#{plan.digest_cache.shorter})"]
      plan.usecases.uniq.each_with_index do |uc,i| 
        
        # TODO: Create Ranges object, like Stats object
        # global_timeline.ranges(:do_request)[:usecase => '1111']
        # The following returns globl do_request ranges. 
        requests = 0 #global_timeline.ranges(:do_request).size
        
        desc = uc.desc || "Usecase ##{i+1} "
        desc << "  (#{uc.digest_cache.shorter}) "
        str = ' ' << " %-66s %s   %d%% ".bright.att(:reverse)
        Stella.li str % [desc, '', uc.ratio_pretty]
        
        uc.requests.each do |req| 
          filter = [uc.digest_cache, req.digest_cache]
          desc = req.desc 
          Stella.li "   %-72s ".bright % ["#{req.desc}  (#{req.digest_cache.shorter})"]
          Stella.li "    %s" % [req.to_s]
          Load.timers.each do |sname|
            stats = global_timeline.stats.group(sname)[filter].merge
#            Stella.li stats.inspect
            str = '      %-30s %.3f <= ' << '%.3fs' << ' >= %.3f; %.3f(SD) %d(N)'
            Stella.li str % [sname, stats.min, stats.mean, stats.max, stats.sd, stats.n]
            Stella.lflush
          end
          Stella.li $/
        end
        
        Stella.li "   Sub Total:".bright
        
        stats = global_timeline.stats.group(:do_request)[uc.digest_cache].merge
        failed = global_timeline.stats.group(:failed)[uc.digest_cache].merge
        respgrp = global_timeline.stats.group(:execute_response_handler)[uc.digest_cache]
        resst = respgrp.tag_values(:status)
        statusi = []
        resst.each do |status|
          size = respgrp[:status => status].size
          statusi << "#{status}: #{size}"
        end
        Stella.li '      %-30s %d (%s)' % ['Total requests', stats.n, statusi.join(', ')]
        Stella.li '       %-29s %d' % [:success, stats.n - failed.n]
        Stella.li '       %-29s %d' % [:failed, failed.n]
        
        Load.timers.each do |sname|
          stats = global_timeline.stats.group(sname)[uc.digest_cache].merge
          Stella.li '      %-30s %.3fs %.3f(SD)' % [sname, stats.mean, stats.sd]
          Stella.lflush
        end
        
        Load.counts.each do |sname|
          stats = global_timeline.stats.group(sname)[uc.digest_cache].merge
          Stella.li '      %-30s %-12s (avg:%s)' % [sname, stats.sum.to_bytes, stats.mean.to_bytes]
          Stella.lflush
        end
        Stella.li $/
      end
      
      Stella.li ' ' << " %-66s ".att(:reverse) % 'Total:'
      stats = global_timeline.stats.group(:do_request).merge
      failed = global_timeline.stats.group(:failed)
      respgrp = global_timeline.stats.group(:execute_response_handler)
      resst = respgrp.tag_values(:status)
      statusi = []
      resst.each do |status|
        size = respgrp[:status => status].size
        statusi << [status, size]
      end
      Stella.li  '      %-30s %d' % ['Total requests', stats.n]
      success = stats.n - failed.n
      Stella.li  '       %-29s %d (req/s: %.2f)' % [:success, success, success/test_time]
      statusi.each do |pair|
        Stella.li2 '        %-28s %s: %d' % ['', *pair]
      end
      Stella.li  '       %-29s %d' % [:failed, failed.n]
      
      Load.timers.each do |sname|
        stats = global_timeline.stats.group(sname).merge
        Stella.li '      %-30s %-.3fs     %-.3f(SD)' % [sname, stats.mean, stats.sd]
        Stella.lflush
      end
      
      Load.counts.each do |sname|
        stats = global_timeline.stats.group(sname).merge
        Stella.li '      %-30s %-12s (avg:%s)' % [sname, stats.sum.to_bytes, stats.mean.to_bytes]
        Stella.lflush
      end
      Stella.li $/
    end
    
    
    def update_prepare_request(client_id, usecase, req, counter)
      
    end
      
    def update_receive_response(client_id, usecase, uri, req, params, counter, container)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.li3 '  Client-%s %3d %-6s %-45s' % [client_id.shorter, container.status, req.http_method, uri]
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
      desc = "#{container.usecase.desc} > #{req.desc}"
      Stella.li $/ if Stella.loglev == 1
      Stella.le '  Client-%s %-45s %s' % [client_id.shorter, desc, ex.message]
      Stella.li3 ex.backtrace
    end
    
    def update_request_error(client_id, usecase, uri, req, params, ex)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.li $/ if Stella.loglev == 1
      Stella.le '  Client-%s %-45s %s' % [client_id.shorter, desc, ex.message]
      Stella.li3 ex.backtrace
    end

    def update_quit_usecase client_id, msg
      Stella.li3 "  Client-%s     QUIT   %s" % [client_id.shorter, msg]
    end
    
    
    def update_repeat_request client_id, counter, total
      Stella.li3 "  Client-%s     REPEAT   %d of %d" % [client_id.shorter, counter, total]
    end
    
    def self.rescue(client_id, &blk)
      blk.call
    rescue => ex
      Stella.le '  Error in Client-%s: %s' % [client_id.shorter, ex.message]
      Stella.li3 ex.backtrace
    end
    
    
    Benelux.add_timer Stella::Engine::Load, :build_thread_package
    Benelux.add_timer Stella::Engine::Load, :execute_test_plan
    Benelux.add_timer Stella::Engine::Load, :generate_report
    Benelux.add_timer Stella::Engine::Load, :wait_for_reporter
    
  end
end

