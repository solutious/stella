Stella::Utils.require_vendor "httpclient", '2.1.5.2'

class Stella::Service
  module V1
    def testplan?(digest)
      req = uri('v1', 'testplan', "#{digest}.json")
      res = send_request :get, req
      !res.content.empty?
    end
    def testplan_create(desc,digest=nil)
      req = uri('v1', 'testplan', "create.json")
      params = {
        :desc => desc,
        :digest => digest
      }
      res = send_request :post, req, params
      if res.status > 200
        raise Stella::Error, res.message
      else
        obj = JSON.parse res.content
        obj['digest']
      end
    end
  end
end

class Stella::Service
  unless defined?(API_VERSION)
    TOKEN = (ENV['STELLA_TOKEN'] || nil).freeze
  end
  
  include Stella::Service::V1
  
  attr_reader :http_client
  attr_accessor :proxy
  attr_reader :conf
  
  attr_reader :source
  attr_reader :apikey
  
  def initialize(source=nil,apikey=nil)
    @source, @apikey = source, apikey
    @proxy = OpenStruct.new
    @http_client = create_http_client
  end
  
  def uri(*parts)
    uri = URI.parse @source
    uri.path = '/api/' << parts.join( '/')
    Stella.ld "SERVICE URI: #{uri}"
    uri
  end
  
  def send_request(meth, uri, params={}, headers={})
    headers['X-TOKEN'] ||= @apikey
    if meth == "delete"
      args = [meth, uri, headers]
    else
      args = [meth, uri, params, headers]
    end
    @http_client.send(*args) # booya!
  end
  
  private
    def create_http_client
      opts = {
        :proxy       => @proxy.uri || nil, # a tautology for clarity
        :agent_name  => "Stella/#{Stella::VERSION}",
        :from        => nil
      }
      http_client = HTTPClient.new opts
      http_client.set_proxy_auth(@proxy.user, @proxy.pass) if @proxy.user
      http_client.debug_dev = STDOUT if Stella.debug? && Stella.log.lev > 1
      http_client.protocol_version = "HTTP/1.1"
      #http_client.ssl_config.verify_mode = ::OpenSSL::SSL::VERIFY_NONE
      http_client
    end
  
end
