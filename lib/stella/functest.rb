


module Stella
  class FunctionalTest
    include TestRunner
    
    
    def run(ns)
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
        puts "setting auth: #{@testplan.auth.user}:#{@testplan.auth.pass} @ #{auth_domain}"
        client.set_auth(auth_domain, @testplan.auth.user, @testplan.auth.pass)
      end
        
      client.set_cookie_store('/tmp/cookie.dat')
      
      #ns.
      
      @testplan.requests.each do |req|
        uri = req.uri.is_a?(URI) ? req.uri : URI.parse(req.uri.to_s)
        uri.scheme ||= @testplan.protocol
        uri.host ||= @testplan.servers.first
        puts "#{req.http_method} #{uri}"
        
        req.response.first[1].call
        
        #if req.http_method =~ /POST|PUT/
        #  body = {}.merge!(req.params)
        #  body[req.body.form_param.to_s] = File.new(req.body.path) if req.body && req.body.path
        #  puts body.keys, body['token']
        #  res = client.post(uri.to_s, body)
        #  
        #  if res && req.response.has_key?(res.status)
        #    req.response[res.status].call(res.header, res.body.content)
        #  else
        #    puts "HTTP #{res.version} #{res.status} (#{res.reason})"
        #    puts res.body.content
        #  end
        #else
        #  
        #end
        
      end
      
      client.save_cookie_store
    end
  end
end
