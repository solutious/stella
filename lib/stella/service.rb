Stella::Utils.require_vendor "httpclient", '2.1.5.2'

class Stella::Service
  class Problem < Stella::Error; end
  module V1
    class NoTestplanSelected < Problem; end
    class NoUsecaseSelected < Problem; end
    class NoRequestSelected < Problem; end
    def testplan?(digest)
      req = uri('v1', 'testplan', "#{digest}.json")
      res = send_request :get, req
      !res.content.empty?
    end
    def testplan_create(desc, opts={})
      req = uri('v1', 'testplan', "create.json")
      params = {
        :desc => desc
      }.merge! opts
      res = send_request :post, req, params
      obj = JSON.parse res.content
      Stella.ld "CREATED TP: #{obj.inspect}"
      @tid = obj['digest']
    end
    def usecase_create(desc, opts={})
      raise NoTestplanSelected unless @tid
      req = uri('v1', 'testplan', 'usecase', "create.json")
      params = {
        :tid  => @tid,
        :desc => desc
      }.merge! opts
      res = send_request :post, req, params
      obj = JSON.parse res.content
      Stella.ld "CREATED UC: #{obj.inspect}"
      @uid = obj['digest']
    end
    def request_create(uri, opts={})
      raise NoUsecaseSelected unless @uid
      req = uri('v1', 'testplan', 'usecase', 'request', "create.json")
      params = {
        :tid  => @tid,
        :uid  => @uid,
        :uri => uri
      }.merge! opts
      res = send_request :post, req, params
      obj = JSON.parse res.content
      @rtid = obj['digest']
    end
    def handler_create(regex, proc)
      raise NoRequestSelected unless @rtid
      req = uri('v1', 'testplan', 'usecase', 'request', 'handler', "create.json")
      params = {
        :tid  => @tid,
        :uid  => @uid,
        :rtid  => @rtid,
        :regex => regex,
        :proc => proc
      }
      res = send_request :post, req, params
      obj = JSON.parse res.content
      obj['digest']
    end
    def sync_testplan(plan)
      #unless testplan? plan.digest
        Stella.stdout.info "Syncing Testplan #{plan.digest.short}"
        testplan_create plan.desc, :digest => plan.digest
        plan.usecases.each do |uc|
          Stella.stdout.info "Syncing Usecase #{uc.digest.short}"
          props = uc.to_hash
          props[:digest] ||= uc.digest
          usecase_create uc.desc, props
          uc.requests.each do |req|
            props = req.to_hash
            props[:digest] ||= req.digest
            props[:desc] = props.delete :description
            handlers = props.delete :response_handler
            request_create props[:uri], props
            handlers.each_pair do |regex, proc|
              handler_create regex, proc
            end
          end
        end
      #end
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
    res = @http_client.send(*args) # booya!
    raise Problem, "#{res.status}: #{res.content}" if res.status > 200
    res
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

