require 'stella/engine/loadbase'

module Stella::Engine
  module Load
    extend Stella::Engine::Load
    extend self
    ROTATE_TIMELINE = 15
    def execute_test_plan(packages, reps=1,duration=0,arrival=nil)
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
          Stella.stdout.info4 $/, "======== THREAD %s: START" % [c.digest.short]  

          # This thread will stay on this one track. 
          Benelux.current_track c.digest
          
          Benelux.add_thread_tags :usecase => uc.digest_cache
          Thread.current[:real_uctime].first_tick
          prev_ptime ||= Time.now
          reps.times { |rep| 
            break if Stella.abort?
            Thread.current[:real_reps] += 1
            # NOTE: It's important to not call digest or gibbler methods
            # on client object b/c it is not frozen. Always use digest_cache.
            args = [c.digest_cache.short, uc.desc, uc.digest.short, Thread.current[:real_reps]]
            Stella.stdout.info4 $/, "======== THREAD %s: %s:%s (rep: %d)" % args
            
            Benelux.add_thread_tags :rep =>  rep
            #Stella.stdout.info [package.client.gibbler.shorter, package.usecase.gibbler.shorter, rep].inspect
            Stella::Engine::Load.rescue(c.digest_cache) {
              break if Stella.abort?
              print '.' if Stella.stdout.lev == 2
              stats = c.execute uc
            }
            Benelux.remove_thread_tags :rep
            
            Thread.current[:real_uctime].tick
            time_elapsed = (Time.now - time_started).to_i
            
            if (Time.now - prev_ptime).to_i >= ROTATE_TIMELINE
              prev_ptime, ruct = Time.now, Thread.current[:real_uctime]
              if Stella.stdout.lev >= 2 && Thread.current == @threads.first 
                args = [time_elapsed.to_i, ruct.n, ruct.mean, ruct.sd]
                Stella.stdout.info2 $/, "REAL UC TIME: %ds (reps: %d): %.4fs %.4f(SD)" % args
              end
              
              Thread.current.rotate_timeline
            end
            
            # If a duration was given, we make sure 
            # to run for only that amount of time.
            if duration > 0
              break if (time_elapsed+Thread.current[:real_uctime].mean) >= duration
              redo if (time_elapsed+Thread.current[:real_uctime].mean) <= duration
            end
          }
          
          Benelux.remove_thread_tags :usecase
          
          pqueue << package  # return the package to the queue
        end
        
        unless arrival.nil?
          # Create 1 second / users per second 
          args = [@threads.size, packages.size]
          Stella.stdout.print 2, '+'
          Stella.stdout.info3 $/, "-> NEW CLIENT: %s of %s" % args
          sleep 1/arrival
        end
      }
      
      repscalc = Benelux::Stats::Calculator.new
      @threads.each { |t| t.join } # wait
      @threads.each { |t| repscalc.sample(t[:real_reps]) }
      @real_reps = repscalc.mean.to_i
      
      #Stella.stdout.info "*** REPETITION #{@real_reps} of #{reps} ***"
      
      Stella.stdout.info2 $/, $/
    end
    
    Benelux.add_timer Stella::Engine::Load, :execute_test_plan
    
  end
end