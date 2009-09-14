
module Stella::Engine
  module Functional
    extend Stella::Engine::Base
    extend self
    
    def run(plan, opts={})
      opts = {
        :hosts        => [],
        :benchmark    => false,
        :repetitions  => 1
      }.merge! opts
      Stella.ld "OPTIONS: #{opts.inspect}"
      Stella.ld "PLANHASH: #{plan.digest}"
      Stella.li2 "Hosts: " << opts[:hosts].join(', ')
      Stella.li2 plan.pretty
      plan.check!  # raise errors
      
      client = Stella::Client.new opts[:hosts].first
      client.add_observer(self)
      client.enable_benchmark_mode if opts[:benchmark]
      
      plan.usecases.each do |uc|
        puts ' %-65s '.att(:reverse).bright % uc.desc
        Stella.rescue { client.execute uc }
      end
    end
    
  end
end

__END__


$ stella verify -p examples/basic/plan.rb http://localhost:3114
$ stella load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-verify -p examples/basic/plan.rb http://localhost:3114

