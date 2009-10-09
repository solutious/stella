
module Stella::Engine
  module Load
    extend Stella::Engine::Base
    extend self
    
    @threads = []
    
    def run(plan, opts={})
      opts = process_options! plan, opts
      
      puts "Not implemented. Try a stress test!"
      
      #Tracer.on
      #Benelux.reporter.wait
      #Tracer.off
      
      #Benelux.timeline
    end
    
    def wait_for_reporter
      Benelux.reporter.wait
    end
    
    protected
    
    
  end
end

