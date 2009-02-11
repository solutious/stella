


module Stella
  class FunctionalTest
    include TestRunner
    
    
    def run
      raise "No testplan defined" unless @testplan
      
      # TODO: one thread for each of @testplan.servers
      
      puts "Running Test: #{@name}"
      puts " -> type: #{self.class}"
      puts " -> testplan: #{@testplan.name}"
      
      if @testplan.proxy
        client = HTTPClient.new(@testplan.proxy.uri)
        client.set_proxy_auth(@testplan.proxy.user, @testplan.proxy.pass) if @testplan.proxy.user
      else
        client = HTTPClient.new
      end
      
      
      if @testplan.auth
        auth_domain = "#{@testplan.protocol}://#{@testplan.servers[0]}/"
        puts "setting auth to:"
        puts " -> domain: #{auth_domain}"
        puts " -> user: #{@testplan.auth.user}"
        puts " -> pass: #{@testplan.auth.pass}"
        client.set_auth(auth_domain, @testplan.auth.user, @testplan.auth.pass)
      end
        
      client.set_cookie_store('/tmp/cookie.dat')
      
      @testplan.requests.each do |req|
        uri = req.uri.is_a?(URI) ? req.uri : URI.parse(req.uri.to_s)
        uri.scheme ||= @testplan.protocol
        uri.host ||= @testplan.servers.first
        puts "#{req.http_method} #{uri}"
        
        if req.body && req.body.path
          File.open(req.body.path) do |file|
            body = { req.body.form_param.to_s => file }
            # TODO: add params
            res = client.post(uri.to_s, body)
            puts res.inspect
          end
        end
      end
      
      client.save_cookie_store
    end
  end
end
