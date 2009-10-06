
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
      opts = {
        :hosts        => [],
        :clients        => 1,
        :time         => nil,
        :nowait    => false,
        :repetitions  => 1
      }.merge! opts
      opts[:clients] = plan.usecases.size if opts[:clients] < plan.usecases.size
      opts[:clients] = 1000 if opts[:clients] > 1000
      
      Stella.ld "OPTIONS: #{opts.inspect}"
      Stella.li3 "Hosts: " << opts[:hosts].join(', ') 
      
      wait_for_reporter
      
      !plan.errors?
    end
    
    def wait_for_reporter
      Benelux.reporter.wait
    end
    
  protected
    
    #Benelux.add_timer Stella::Engine::Load, :build_thread_package
    
  end
end

