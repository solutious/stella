require "observer"
require "tempfile"


module Stella
  class Client
    include Observable
    attr_reader :client_id
    
    def inititalize(client_id=1)
      @client_id = client_id
      @cookie_file = Tempfile.new('stella-cookie')
    end
    
    def execute(plan)
      http_client = generate_http_client
    end
    
  private
    def generate_http_client
      #if env.proxy
      #  http_client = HTTPClient.new(env.proxy.uri)
      #  if env.proxy.user
      #    http_client.set_proxy_auth(env.proxy.user, env.proxy.pass) 
      #  end
      #else
        http_client = HTTPClient.new
      #end
      http_client.set_cookie_store @cookie_file.to_s
      http_client
    end
    
  end
end