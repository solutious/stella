
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
      Stella.ld "PLANHASH: #{plan.digest}"
      Stella.li2 plan.pretty
      plan.check!  # raise errors
      
      client = Stella::Client.new
      client.execute plan
    end
    
  end
end

__END__


$ stella verify -p examples/basic/plan.rb http://localhost:3114
$ stella load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-verify -p examples/basic/plan.rb http://localhost:3114

