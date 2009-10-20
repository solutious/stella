
module Stella::Engine
  module LoadQueue
    extend Stella::Engine::Base
    extend Stella::Engine::Load
    extend self
    
    def execute_test_plan(packages, reps=1,duration=0)
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
          c, uc = package.client, package.usecase
          Stella.li4 $/, "======== THREAD %s: START" % [c.digest.short]  

          # This thread will stay on this one track. 
          Benelux.current_track c.digest
          Benelux.add_thread_tags :usecase => uc.digest_cache
          
          uctime = Benelux::Stats::Calculator.new
          uctime.first_tick
          reps.times { |rep| 
            Thread.current[:real_reps] += 1
            args = [c.digest.short, uc.desc, uc.digest.short, Thread.current[:real_reps]]
            Stella.li4 $/, "======== THREAD %s: %s:%s (rep: %d)" % args
            
            Benelux.add_thread_tags :rep =>  rep
            #Stella.li [package.client.gibbler.shorter, package.usecase.gibbler.shorter, rep].inspect
            Stella::Engine::Load.rescue(c.digest_cache) {
              break if Stella.abort?
              print '.' if Stella.loglev == 2
              stats = c.execute uc
            }
            Benelux.remove_thread_tags :rep
            
            uctime.tick
            
            # If a duration was given, we make sure 
            # to run for only that amount of time.
            if duration > 0
              time_elapsed = (Time.now - time_started).to_i
              break if (time_elapsed+uctime.mean) >= duration
              redo if (time_elapsed+uctime.mean) <= duration
            end
          }
          
          Benelux.remove_thread_tags :usecase
          
          pqueue << package  # return the package to the queue
        end
      }
      
      repscalc = Benelux::Stats::Calculator.new
      @threads.each { |t| t.join } # wait
      @threads.each { |t| repscalc.sample(t[:real_reps]) }
      @real_reps = repscalc.mean.to_i
      
      #Stella.li "*** REPETITION #{@real_reps} of #{reps} ***"
      
      Stella.li2 $/, $/
    end
    
    Benelux.add_timer Stella::Engine::LoadQueue, :execute_test_plan
    
  end
end