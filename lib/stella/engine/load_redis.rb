require 'redis'

module Stella::Engine
  module LoadRedis
      extend Stella::Engine::Base
        extend Stella::Engine::Load
          extend Stella::Engine::LoadQueue
    extend self
    ROTATE_TIMELINE = 15
    def prepare_dumper(plan, opts)
      redis = Redis.new :password => opts[:redis_pass], 
                        :host => opts[:redis_host], 
                        :port => opts[:redis_port]
      
      redis.set_add 'runs', runid(plan)
      Stella::Hand.new(5.seconds, 2.seconds) do
        Benelux.update_global_timeline
        #reqlog.info [Time.now, Benelux.timeline.size].inspect
        @reqlog.info Benelux.timeline.messages.filter(:kind => :request)
        @failog.info Benelux.timeline.messages.filter(:kind => :exception)
        @failog.info Benelux.timeline.messages.filter(:kind => :timeout)
        @authlog.info Benelux.timeline.messages.filter(:kind => :authentication)
        @reqlog.clear and @failog.clear and @authlog.clear
        #generate_runtime_report(plan)
        redis['pop'] = rand
        Benelux.timeline.clear if opts[:"disable-stats"]
      end

    end
    
  end
end