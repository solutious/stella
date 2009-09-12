
module Stella::Engine
  module Functional
    extend Stella::Engine::Base
    extend self

    def run(plan, opts={})
      opts = {
        :duration     => nil,
        :repetitions  => 1
      }.merge! opts
      Stella.ld "OPTIONS: #{opts.inspect}"
      Stella.ld "RUNNING: #{plan.inspect}"
    end
    
  end
end