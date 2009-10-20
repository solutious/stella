
module Stella::Engine
  module LoadQueue
    extend Stella::Engine::Base
    extend Stella::Engine::Load
    extend self
    
    
    def execute_test_plan(packages, reps=1,duration=0)
      Stella.li2 $/, $/
    end
    
    Benelux.add_timer Stella::Engine::LoadQueue, :execute_test_plan
    
  end
end