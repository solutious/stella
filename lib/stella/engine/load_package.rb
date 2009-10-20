
module Stella::Engine
  module LoadPackage
    extend Stella::Engine::Base
    extend Stella::Engine::Load
    extend self
    
    
    def execute_test_plan(packages, reps=1,duration=0)
      require 'threadify'
      
      Thread.ify packages, :threads => packages.size do |package|
        Thread.current[:real_reps] = 0
        # This thread will stay on this one track. 
        Benelux.current_track package.client.gibbler
        Benelux.add_thread_tags :usecase => package.usecase.digest_cache
        (1..reps).to_a.each do |rep|
          Thread.current[:real_reps] += 1
          Benelux.add_thread_tags :rep =>  rep
          Stella::Engine::Load.rescue(package.client.digest_cache) {
            break if Stella.abort?
            print '.' if Stella.loglev == 2
            stats = package.client.execute package.usecase
          }
          Benelux.remove_thread_tags :rep
          Stella.sleep :check_threads
        end
        
        Benelux.remove_thread_tags :usecase
        
      end
      
      Stella.li2 $/, $/
    end
    
    Benelux.add_timer Stella::Engine::LoadPackage, :execute_test_plan
    
  end
end