
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
    def initialize(opts={})
      @index = @@client_index += 1
      @created = Time.now.to_f
      @opts = opts
      @base_uri, @index = opts[:base_uri] || opts['base_uri'], index
      @proxy = OpenStruct.new
      @done = false
      @session = Session.new
    end

    def execute usecase
      http_client = create_http_client
      tt = Benelux.current_track.timeline
      usecase.requests.each_with_index do |req,idx|
        begin 
          params = req.params || {}
          headers = req.headers || {}
          stella_id = [Stella.now, index, req.id, params, headers, idx].digest
          built_uri = build_uri(req.uri)
          
          Benelux.current_track.add_tags :request   => req.id
          Benelux.current_track.add_tags :stella_id => stella_id
          
          ## Useful for testing larger large request header
          ## 50.times do |idx|
          ##   headers["X-header-#{idx}"] = (1000 << 1000).to_s
          ## end
          
          res = http_client.get(built_uri, params, headers)
          @session.events << stella_id
          
          raise Stella::HTTPError, res.status if res.status >= 400
          
          log = Stella::Log::HTTP.new Stella.now,  
                   req.http_method, built_uri, params, res.request.header.dump, 
                   res.request.body.content, res.status, res.header.dump, res.body.content
          
          tt.add_message log, :status => res.status, :kind => :http_log
          
        rescue HTTPClient::ConnectTimeoutError, 
               HTTPClient::SendTimeoutError,
               HTTPClient::ReceiveTimeoutError,
               Errno::ECONNRESET => ex
          Stella.ld "[#{ex.class}] #{ex.message}"
          log = Stella::Log::HTTP.new Stella.now, req.http_method, built_uri, params
          if res 
            log.request_headers = res.request.header.dump if res.request 
            log.request_body = res.request.body.content if res.request 
            log.response_status = res.status
            log.response_headers = res.header.dump if res.content
            log.response_body = res.body.content if res.body
          end
          log.msg = "#{ex.class} (#{http_client.receive_timeout})"
          tt.add_message log, :kind => :http_log, :state => :timeout
          Benelux.current_track.remove_tags :status, :request, :stella_id
          next
        rescue Stella::HTTPError => ex
          Stella.ld "[#{ex.class}] #{ex.message}"
          log = Stella::Log::HTTP.new Stella.now, req.http_method, built_uri, params
          if res 
            log.request_headers = res.request.header.dump if res.request 
            log.request_body = res.request.body.content if res.request 
            log.response_status = res.status
            log.response_headers = res.header.dump if res.content
            log.response_body = res.body.content if res.body
          end
          log.msg = ex.message
          tt.add_message log, :status => log.response_status, :kind => :http_log, :state => :exception
          Benelux.current_track.remove_tags :status, :request, :stella_id
          break
        rescue => ex
          Stella.le "[#{ex.class}] #{ex.message}", ex.backtrace
          break
        end
      end
    end
    
    def build_uri uri
      uri
    end
    
    def create_http_client
      client_opts = {
        :agent_name  => @opts[:agent] || @opts['agent'] || Stella.agent,
        :from        => nil
      }
      http_client = HTTPClient.new client_opts
      #http_client.set_proxy_auth(@proxy.user, @proxy.pass) if @proxy.user
      #http_client.debug_dev = STDOUT if Stella.debug?
      http_client.protocol_version = "HTTP/1.1"
      #http_client.ssl_config.verify_mode = ::OpenSSL::SSL::VERIFY_NONE
      if @opts[:timeout]
        http_client.connect_timeout = @opts[:timeout]
        http_client.send_timeout = @opts[:timeout]
        http_client.receive_timeout = @opts[:timeout]
      end
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
