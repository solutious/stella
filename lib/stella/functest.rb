


module Stella
  class FunctionalTest
    include TestRunner
    
    # +namespace+ is a reference to the namespace which contains the instance
    # variables. This will be the section of code that makes use of the DSL.
    def run(namespace, environment)
      raise "No testplan defined" unless @testplan
      
      
      puts "Running Test: #{@name}"
      puts " -> type: #{self.class}"
      puts " -> testplan: #{@testplan.name}"
      
      #if @testplan.proxy
      #  client = HTTPClient.new(@testplan.proxy.uri)
      #  client.set_proxy_auth(@testplan.proxy.user, @testplan.proxy.pass) if @testplan.proxy.user
      #else
        client = HTTPClient.new
      #end
      
      # TODO: one thread for each of environment.machines
      
      if @testplan.auth
        auth_domain = "#{@testplan.protocol}://#{environment.machines.first.to_s}/"
        puts "setting auth: #{@testplan.auth.user}:#{@testplan.auth.pass} @ #{auth_domain}"
        client.set_auth(auth_domain, @testplan.auth.user, @testplan.auth.pass)
      end
        
      client.set_cookie_store('/tmp/cookie.dat')
      
      request_methods = namespace.methods.select { |meth| meth =~ /\d+\s[A-Z]/ }
      
      @retries = 1
      previous_methname = nil
      request_methods.each do |methname|
        @retries = 1 unless previous_methname == methname
        previous_methname = methname
        
        # We need to define the request only the first time it's run. 
        req = namespace.send(methname) unless @retries > 1
        puts 
        
        uri = req.uri.is_a?(URI) ? req.uri : URI.parse(req.uri.to_s)
        uri.scheme ||= @testplan.protocol
        uri.host ||= environment.machines.first.host
        uri.port ||= environment.machines.first.port
        puts "#{req.http_method} #{uri}"
        
        query = {}.merge!(req.params)
        
        if req.http_method =~ /POST|PUT/
          query[req.body.form_param.to_s] = File.new(req.body.path) if req.body && req.body.path
          res = client.post(uri.to_s, query)
        elsif req.http_method =~ /GET|HEAD/
          res = client.get(uri.to_s, query)
          p query if @verbose > 0
        end
        
        puts "HTTP #{res.version} #{res.status} (#{res.reason})"
        
        if res && req.response.has_key?(res.status)
          response_handler_ret = req.response[res.status].call(res.header, res.body.content)
          
          if response_handler_ret.is_a?(Stella::TestPlan::ResponseHandler) && response_handler_ret.action == :repeat
            @retries ||= 1
            
            if @retries > response_handler_ret[:times]
              puts "Giving up."
              @retries = 1
              next
            else  
              print "repeat #{@retries} of #{response_handler_ret[:times]} "
              run_sleeper(response_handler_ret[:wait])
              puts
              @retries += 1
              redo
            end
          end
        else
          puts res.body.content[0..100]
          puts '...' if res.body.content.length >= 100
        end
        
        puts
      end
      
      client.save_cookie_store
    end
    
    def run_sleeper(duration, quiet=false)
      remainder = duration % 1 
      duration.to_i.times {
        print '.' unless duration <= 1 || quiet
        sleep 1
      }
      sleep remainder if remainder > 0
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
