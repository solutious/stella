# See, re Threadify on JRuby: http://www.ruby-forum.com/topic/158180

#
#
module Stella
  class LoadTest
    include TestRunner

    attr_accessor :clients
    attr_accessor :repetitions
    attr_accessor :duration
    
    attr_reader :testplans_started
    attr_reader :testplans_completed
    
    attr_reader :requests_successful
    attr_reader :requests_failed
    
    def init
      @repetitions = 1
      @clients = 1
      @duration = 0
      reset
    end
    
    def reset
      @testplans_started = 0
      @testplans_completed = 0
      @requests_successful = 0
      @requests_failed = 0
    end
    
    def type; "load"; end
    
    def requests_total
      @requests_successful + @requests_failed
    end
    
    def update_start(machine, name)
      @testplans_started += 1
    end
    
    def update_done(*args)
      @testplans_completed += 1
    end
    
    def update_authorized(domain, user, pass)
    end
    
    def update_request(method, uri, query, response_status, response_headers, response_body)
      @requests_successful += 1
    end
    
    def update_request_exception(method, uri, query, ex)
      @requests_failed += 1
      puts [method, uri, query, ex.message].join("|")
    end
    
    def update_request_unexpected_response(method, uri, query, response_status, response_headers, response_body)
      @requests_failed += 1
      #puts [method, uri, query, response_status, response_headers, response_body].join("|")
    end
    
    def update_retrying(uri, retry_count, total)
      #print retry_count
    end
    
    
    # +environment+ is a Stella::Common::Environment object. 
    # +namespace+ is a reference to the namespace which contains the instance
    # variables. 
    def run(environment, namespace)
      raise "No testplan defined" unless @testplan
      raise "No machines defined for #{environment.name}" if environment.machines.empty?

      [:duration, :clients, :repetitions].each do |p|
        val = instance_variable_get("@#{p}")
        puts " %11s: %s" % [p, val] if val
      end
      
      stats = Stats.new("LoadTest")
      request_stats = {}

      time_started = Time.now
      seconds_elapsed = 0
      (1..@clients).to_a.threadify do |i|
        
        (0..@repetitions).to_a.each do |rep|

          if environment.proxy
            http_client = HTTPClient.new(environment.proxy.uri)
            http_client.set_proxy_auth(environment.proxy.user, environment.proxy.pass) if environment.proxy.user
          else
            http_client = HTTPClient.new
          end


          environment.machines.each do |machine|
            client = Stella::Client.new(i)
            client.add_observer(self)
            client.execute_testplan(request_stats, http_client, machine, namespace, @testplan, @verbose)
          end
          
          seconds_elapsed = Time.now - time_started

          #request_stats.each do |rstat|
          #  puts rstat[1][:stats].to_s
          #end
          
          # If a duration was given, we make sure to run for that
          # amount of time.
          if @duration > 0
            redo if seconds_elapsed <= @duration 
            break if seconds_elapsed >= @duration
          end
        end
      end

      stats.tick
      puts "DONE! (#{seconds_elapsed.minutes} minutes)"
      instance_variables.each do |name|
        #next unless name =~ /request/
        puts "%20s: %s" % [name, instance_variable_get(name)]
      end
      
      puts "Final Status"
      puts stats.to_s
      puts

      request_stats.each do |rstat|
        puts rstat[1][:stats].to_s
      end
    end
    
    
    def clients=(*args)
      count = args.flatten.first
      @clients = count
    end
    
    def repetitions=(*args)
      @repetitions = args.flatten.first
    end
    
    def duration=(*args)
      @duration = args.flatten.first
    end
  end
end







module Stella
  module DSL 
    module LoadTest
      include Stella::DSL::TestRunner
      
      def loadtest(name=:default, &define)
        @tests ||= {}
        @current_test = @tests[name] = Stella::LoadTest.new(name)
        define.call if define
      end
      
      def rampup(*args)
      end 
      
      def warmup(*args)
      end
          
      [:repetitions, :duration, :clients].each do |method_name|
        eval <<-RUBY, binding, '(Stella::DSL::LoadTest)', 1
        def #{method_name}(*val)
          return unless @current_test.is_a? Stella::LoadTest
          @current_test.#{method_name}=(val)
        end
        private :#{method_name}
        RUBY
      end
      
    end
  end
end