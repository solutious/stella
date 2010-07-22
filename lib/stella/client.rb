
require 'base64'
require 'addressable/uri'

Stella::Utils.require_vendor "httpclient", '2.1.5.2'

require 'pp'

class Stella
  class Session
    attr_reader :events
    def initialize
      @events = SelectableArray.new
    end
    def current_event
      @events.last
    end
  end
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
      @session = Session.new
    end

    def execute usecase
      http_client = create_http_client
      tt = Benelux.thread_timeline
      usecase.requests.each_with_index do |req,idx|
        begin 
          params = req.params
          headers = req.headers
          stella_id = [Stella.now, index, req.id, params, headers, idx].digest
          built_uri = build_uri(req.uri)
          
          Benelux.add_thread_tags :request   => req.id
          Benelux.add_thread_tags :stella_id => stella_id
          
          res = http_client.get(built_uri)
          @session.events << stella_id
          log = Stella::Log::HTTP.new Stella.now,  
                   req.http_method, res.status, built_uri, params, 
                   res.request.header.dump, res.request.body.content, 
                   res.header.dump, res.body.content
                   
          tt.add_message log, :status => res.status, :kind => :http_log
        
        rescue HTTPClient::ConnectTimeoutError, 
               HTTPClient::SendTimeoutError,
               HTTPClient::ReceiveTimeoutError,
               Errno::ECONNRESET => ex
          Stella.le ex.message, ex.backtrace
          #update(:request_timeout, usecase, uri, req, params, headers, counter, container, http_client.receive_timeout)
          Benelux.remove_thread_tags :status, :request, :stella_id
          next
        rescue => ex
          Stella.le ex.message, ex.backtrace
          #update(:request_unhandled_exception, usecase, uri, req, params, ex)
          Benelux.remove_thread_tags :status, :request, :stella_id
          break
        end
      end
    end
    
    def build_uri uri
      uri
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
