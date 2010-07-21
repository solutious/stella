
require 'base64'
require 'addressable/uri'

Stella::Utils.require_vendor "httpclient", '2.1.5.2'

class Stella
  class Client
    include Gibbler::Complex
    
    attr_reader :index
    attr_accessor :base_uri
    attr_accessor :proxy
    attr_accessor :created 
    
    gibbler :index, :opts, :base_uri, :proxy, :created
    
    @@client_index = 0
    def initialize(base_uri=nil, opts={})
      @index = @@client_index += 1
      @created = Time.now.to_f
      @opts = opts
      @base_uri, @index = base_uri, index
      @proxy = OpenStruct.new
      @done = false
    end
    
    def execute usecase
      http_client = create_http_client
      usecase.requests.each_with_index do |req,idx|
        begin 
          http_client.get(req.uri)
        rescue => ex
          update(:request_unhandled_exception, usecase, uri, req, params, ex)
          Benelux.remove_thread_tags :status, :retry, :request, :stella_id
          break
        end
      end
    end
    
    def create_http_client
      opts = {
        :proxy       => @proxy.uri || nil, # a tautology for clarity
        :agent_name  => Stella.agent,
        :from        => nil
      }
      http_client = HTTPClient.new opts
      http_client.set_proxy_auth(@proxy.user, @proxy.pass) if @proxy.user
      #http_client.debug_dev = STDOUT if Stella.debug?
      http_client.protocol_version = "HTTP/1.1"
      #http_client.ssl_config.verify_mode = ::OpenSSL::SSL::VERIFY_NONE
      http_client
    end
    
    def done!
      @done = true
    end
    
    def done?
      @done == true
    end
    
  end
end
