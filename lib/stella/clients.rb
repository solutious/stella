
require "observer"



module Stella
  class Client
    include Observable
    
    def execute_testplan(http_client, machine, namespace, plan, verbose=1)
      changed
      notify_observers(:start, machine, plan.name)
      
      if plan.auth
        auth_domain = "#{plan.protocol}://#{machine.to_s}/"
        http_client.set_auth(auth_domain, plan.auth.user, plan.auth.pass)
        changed
        notify_observers(:authorized, auth_domain, plan.auth.user, plan.auth.pass)
      end
      
      http_client.set_cookie_store('/tmp/cookie.dat')
    
      request_methods = namespace.methods.select { |meth| meth =~ /\d+\s[A-Z]/ }
      
      retry_count = 1
      previous_methname = nil
      request_methods.each do |methname|
        retry_count = 1 unless previous_methname == methname
        previous_methname = methname
      
        # We need to define the request only the first time it's run. 
        req = namespace.send(methname) unless retry_count > 1 
      
        uri = req.uri.is_a?(URI) ? req.uri : URI.parse(req.uri.to_s)
        uri.scheme ||= plan.protocol
        uri.host ||= machine.host
        uri.port ||= machine.port
        
      
        query = {}.merge!(req.params)
      
        if req.http_method =~ /POST|PUT/
          body = File.new(req.body.path) if req.body && req.body.path
        
          if req.body.form_param.nil? && query.empty?
            query = body
          else
            query[req.body.form_param.to_s] = body
          end
        end
        
        begin
          res = http_client.send(req.http_method.downcase, uri.to_s, query)
        rescue => ex
          changed
          notify_observers(:request_exception, req.http_method, uri, query, ex.message)
          next
        end
        
        
        response_headers = res.header.all.stella_to_hash
        

        
        unless req.response.has_key?(res.status)
          changed
          notify_observers(:request_unexpected_response, req.http_method, uri, query, res.status, response_headers, res.body.content)
        else
          
          changed
          notify_observers(:request, req.http_method, uri, query, res.status, response_headers, res.body.content)
          
          response_handler_ret = req.response[res.status].call(response_headers, res.body.content)
        
          if response_handler_ret.is_a?(Stella::TestPlan::ResponseHandler) && response_handler_ret.action == :repeat
            retry_count ||= 1
          
            if retry_count > response_handler_ret.times
              retry_count = 1
              next
            else  
              changed
              notify_observers(:retrying, uri, retry_count, response_handler_ret.times)
              run_sleeper(response_handler_ret.wait)
              retry_count += 1
              redo
            end
          end
        end
        
      end
      
      http_client.save_cookie_store
      changed
      notify_observers(:done)
      
    end
  
    def run_sleeper(duration, quiet=true)
      remainder = duration % 1 
      duration.to_i.times {
        print '.' unless duration <= 1 || quiet
        sleep 1
      }
      sleep remainder if remainder > 0
    end  
  end
end

#module Stella
#  class Clients
#
#      # The default authentication, a Stella::Common::Auth object
#    attr_accessor :auth
#    
#  end
#end

#module Stella
#  module DSL
#    module Clients
#      
#      def clients(name = :anonymous, &define)
#        @stella_clients ||= {}
#        @stella_clients[name] = []
#      end
#    end
#  end
#end