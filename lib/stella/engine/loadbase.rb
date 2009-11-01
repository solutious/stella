
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
      
      Stella.datalogger = Logger.new Stella::Data::Dumper.log_dir('requests')
      Stella.datalogger << "Started at #{Time.now.to_i}"
      
      if Stella.log.lev > 2
        Load.timers += [:query, :connect, :socket_gets_first_byte, :get_body]
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
      
      bt = Benelux.timeline
      
      begin
        execute_test_plan packages, opts[:repetitions], opts[:duration], opts[:arrival]
      rescue Interrupt
        Stella.li "Stopping test...", $/
        Stella.abort!
        @threads.each { |t| t.join } unless @threads.nil? || @threads.empty? # wait
      ensure
        Stella.li "Processing statistics...", $/
        Stella.lflush
        
        Benelux.update_global_timeline
        
        tt = Benelux.thread_timeline
        
        test_time = tt.stats.group(:execute_test_plan).mean
        generate_report plan, test_time
        report_time = tt.stats.group(:generate_report).mean
        
        # Here is the calcualtion for the number of
        # Benelux assets created for each request:
        # 
        #     [5*2*REQ+6, 5*1*REQ+3, 13*REQ]
        # 
        
        Stella.li "Summary: "
        Stella.li "  max clients: %d" % @max_clients
        Stella.li "  repetitions: %d" % @real_reps
        Stella.li "    test time: %10.2fs" % test_time
        Stella.li "    post time: %10.2fs" % report_time
        Stella.li $/
      end
      
      Stella.datalogger << "Ended at #{Time.now.to_i}"
      
      bt.stats.group(:failed).merge.n == 0
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
          copts = {}
          copts[:parse_templates] = false if opts[:'disable-templates']
          client = Stella::Client.new opts[:hosts].first, index+1, copts
          client.add_observer(self)
          client.enable_nowait_mode if opts[:nowait]
          Stella.li4 "Created client #{client.digest.short}"
          ThreadPackage.new(index+1, client, usecase)
        end
        pointer += count
      end
      packages.compact # TODO: Why one nil element sometimes?
    end
    
    def execute_test_plan(*args)
      raise "Override execute_test_plan method in #{self}"
    end
    
    def running_threads
      @threads.select { |t| t.status }  # non-false status are still running
    end
    def generate_report(plan,test_time)
      #Benelux.update_all_track_timelines
      global_timeline = Benelux.timeline
      global_stats = global_timeline.stats.group(:do_request).merge
      if global_stats.n == 0
        Stella.ld "No stats"
        return
      end
      
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
      
      failed = global_timeline.stats.group(:failed)
      respgrp = global_timeline.stats.group(:execute_response_handler)
      resst = respgrp.tag_values(:status)
      statusi = []
      resst.each do |status|
        size = respgrp[:status => status].size
        statusi << [status, size]
      end
      Stella.li  '      %-30s %d' % ['Total requests', global_stats.n]
      success = global_stats.n - failed.n
      Stella.li  '       %-29s %d (req/s: %.2f)' % [:success, success, success/test_time]
      statusi.each do |pair|
        Stella.li3 '        %-28s %s: %d' % ['', *pair]
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
      args = [client_id.shorter, container.status, req.http_method, uri, params.inspect]
      Stella.li2 '  Client-%s %3d %-6s %s %s' % args
      Stella.ld '  Client-%s %3d %s' % [client_id.shorter, container.status, container.body]
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
      desc = "#{container.usecase.desc} > #{req.desc}"
      Stella.li $/ if Stella.log.lev == 1
      Stella.le '  Client-%s %-45s %s' % [client_id.shorter, desc, ex.message]
      Stella.li ex.backtrace
    end
    
    def update_request_error(client_id, usecase, uri, req, params, ex)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.li $/ if Stella.log.lev == 1
      Stella.le '  Client-%s %-45s %s' % [client_id.shorter, desc, ex.message]
      Stella.li ex.backtrace
    end

    def update_quit_usecase client_id, msg

      Stella.li2 "  Client-%s     QUIT   %s" % [client_id.shorter, msg]
    end
    
    def update_fail_request client_id, msg
      Stella.li2 "  Client-%s     FAILED   %s" % [client_id.shorter, msg]
    end
    
    def update_repeat_request client_id, counter, total
      Stella.li2 "  Client-%s     REPEAT   %d of %d" % [client_id.shorter, counter, total]
    end
    
    def self.rescue(client_id, &blk)
      blk.call
    rescue => ex
      Stella.le '  Error in Client-%s: %s' % [client_id.shorter, ex.message]
    end
    
    Benelux.add_timer Stella::Engine::Load, :build_thread_package
    Benelux.add_timer Stella::Engine::Load, :generate_report
        
  end
end

