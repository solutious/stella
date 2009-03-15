
require "observer"
require "tempfile"


module Stella
  class Client
    include Observable
    
    attr_reader :request_stats
    attr_accessor :client_id
    def initialize(client_id=1)
      @client_id = client_id
      @request_stats = {
      }
    end
    
    def execute_testplan(request_stats, http_client, machine, namespace, plan, verbose=1)
      changed
      notify_observers(:start, machine, plan.name)
      
      if plan.auth
        auth_domain = "#{plan.protocol}://#{machine.to_s}/"
        http_client.set_auth(auth_domain, plan.auth.user, plan.auth.pass)
        changed
        notify_observers(:authorized, auth_domain, plan.auth.user, plan.auth.pass)
      end
      
      tf = Tempfile.new('stella-cookie')
      http_client.set_cookie_store(tf.to_s)
    
      request_methods = namespace.methods.select { |meth| meth =~ /\d+\s[A-Z]/ }
      
      retry_count = 1
      previous_methname = nil
      request_methods.each do |methname|
        retry_count = 1 unless previous_methname == methname
        previous_methname = methname
        
        # We need to define the request only the first time it's run. 
        req = namespace.send(methname) unless retry_count > 1 
        req.set_unique_id(self.object_id)
        
        request_stats[req.stella_id.to_sym] ||= {
          :name => req.name,
          :stats => Stats.new( req.name )
        }
        
        uri = req.uri.is_a?(URI) ? req.uri : URI.parse(req.uri.to_s)
        uri.scheme ||= plan.protocol
        uri.host ||= machine.host
        uri.port ||= machine.port
        
        query = {}.merge!(req.params)
        
        
        
        begin
          
          if req.http_method =~ /POST|PUT/
            
            if req.body.has_content?
              body = req.body.content
              param = req.body.form_param || 'file'  # How do we handle bodies with no form name?
              query[param] = body # NOTE: HTTPClient prefers a file handle rather than reading in the file
            end

          end
          
          # Make the request. 
          time_started = Time.now
          res = http_client.send(req.http_method.downcase, uri.to_s, query)
          request_stats[req.stella_id.to_sym][:stats].sample(Time.now - time_started)
          
        rescue => ex
          changed
          notify_observers(:request_exception, req.http_method, uri, query, ex)
          next
        end
        
        
        response_headers = res.header.all.stella_to_hash
        

        
        unless req.response_handler.has_key?(res.status)
          changed
          notify_observers(:request_unexpected_response, req.http_method, uri, query, res.status, response_headers, res.body.content)
        else
          
          changed
          notify_observers(:request, req.http_method, uri, query, res.status, response_headers, res.body.content)
          
          response_handler_ret = req.response_handler[res.status].call(response_headers, res.body.content, @client_id)
        
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