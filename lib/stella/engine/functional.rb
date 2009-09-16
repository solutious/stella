
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
      Stella.li2 "Hosts: " << opts[:hosts].join(', ') if !opts[:hosts].empty?
      Stella.li "Testplan:", plan.pretty
      
      client = Stella::Client.new opts[:hosts].first
      client.add_observer(self)
      client.enable_benchmark_mode if opts[:benchmark]
      
      Stella.li $/, "Running:"
      plan.usecases.each_with_index do |uc,i|
        desc = (uc.desc || "Usecase ##{i+1}")
        Stella.li ' %-65s '.att(:reverse).bright % [desc]
        Stella.rescue { client.execute uc }
      end
      
      Drydock::Screen.flush
    end
    
  end
end

__END__


$ stella verify -p examples/basic/plan.rb http://localhost:3114
$ stella load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-load -p examples/basic/plan.rb http://localhost:3114
$ stella remote-verify -p examples/basic/plan.rb http://localhost:3114

