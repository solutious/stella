


module Stella
  class FunctionalTest
    include TestRunner
    
    def type; "functional"; end
    
    
    
    def update_start(machine, name)
      puts '-'*60
      puts "%10s: %s" % ["MACHINE", machine]  
    end
    
    def update_authorized(domain, user, pass)
      note = user
      note += ":****" if pass
      puts "%10s: %s" % ["user", note]
      puts
    end
    
    def update_request(method, uri, query, response_status, response_headers, response_body)
      puts "#{method} #{uri}"
      puts "%18s: %s" % ["status", response_status]
      puts "%18s: %s" % ["query", query] if @verbose > 0 && !query.empty?
      puts "%18s: %s" % ["response_headers", response_headers]
      puts "%18s: #{$/}%s" % ["response_body", response_body[0..100]] if @verbose > 0
      puts
    end
    
    def update_request_exception(method, uri, query, ex)
      puts "#{method} #{uri}"
      puts "EXCEPTION: #{ex.message}"
      puts ex.backtrace
    end
    
    def update_request_unexpected_response(method, uri, query, response_status, response_headers, response_body)
      puts "#{method} #{uri}"
      puts "%18s: %s" % ["status", response_status]
      puts "%18s: %s" % ["note", "unexpected response status"]
      puts "", response_body[0..500]
      puts '...' if response_body.length >= 500
    end
    
    def update_retrying(uri, retry_count, total)
      puts "retrying: #{uri} (#{retry_count} of #{total})"
    end


    # +environment+ is a Stella::Common::Environment object. 
    # +namespace+ is a reference to the namespace which contains the instance
    # variables. This will be the section of code that makes use of the DSL.
    def run(environment, namespace)
      raise "No testplan defined" unless @testplan
      raise "No machines defined for #{environment.name}" if environment.machines.empty?
      
      
      begin
        if environment.proxy
          http_client = HTTPClient.new(environment.proxy.uri)
          http_client.set_proxy_auth(environment.proxy.user, environment.proxy.pass) if environment.proxy.user
        else
          http_client = HTTPClient.new
        end
      rescue => ex
        puts ex.class
      end
      
      request_stats = {}
      environment.machines.each do |machine|
        client = Stella::Client.new
        client.add_observer(self)
        client.execute_testplan(request_stats, http_client, machine, namespace, @testplan, @verbose)
      end
      

      request_stats.each do |rstat|
        puts rstat[1][:stats].to_s
      end
    end
    

  end
end




module Stella
    module DSL 
      module FunctionalTest
        include Stella::DSL::TestRunner
      
      def functest(name=:default, &define)
        @tests ||= {}
        @current_test = @tests[name] = Stella::FunctionalTest.new(name)
        define.call if define
      end
      
      
    end
  end
end
