Stella::Utils.require_vendor "httpclient", '2.1.5.2'

class Hash
  
  # Courtesy of Julien Genestoux
  def flatten
    params = {}
    stack = []

    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      elsif v.is_a?(Array)
        stack << [k,Hash.from_array(v)]
      else
        params[k] =  v
      end
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params["#{parent}[#{k}]"] = v
        end
      end
    end

    params
  end
  
  # Courtesy of Julien Genestoux
  # See: http://stackoverflow.com/questions/798710/how-to-turn-a-ruby-hash-into-http-params
  def to_params
    params = ''
    stack = []

    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      elsif v.is_a?(Array)
        stack << [k,Hash.from_array(v)]
      else
        params << "#{k}=#{v}&"
      end
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end

    params.chop! 
    params
  end
  def self.from_array(array = [])
    h = Hash.new
    array.size.times do |t|
      h[t] = array[t]
    end
    h
  end

end


class Stella::Service
  attr_accessor :runid, :tid, :uid, :rtid
  class Problem < Stella::Error
    def res() @obj end
  end
  module V1
    class NoTestplanSelected < Problem; end
    class NoUsecaseSelected < Problem; end
    class NoRequestSelected < Problem; end
    class NoTestrunSelected < Problem; end
    def testplan?(digest)
      req = uri('v1', 'testplan', "#{digest}.json")
      res = send_request :get, req
      !res.content.empty?
    rescue Stella::Service::Problem => ex
      raise ex unless ex.res.status == 404
      false
    end
    def testrun?(digest)
      req = uri('v1', 'testrun', "#{digest}.json")
      res = send_request :get, req
      !res.content.empty?
    rescue Stella::Service::Problem => ex
      raise ex unless ex.res.status == 404
      false
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
    def testrun_create(opts={})
      raise NoTestplanSelected unless @tid
      req = uri('v1', 'testrun', "create.json")
      params = {
        :tid => @tid,
        :v => Stella::VERSION.to_s,
        :start_at => Stella::START_TIME.to_i
      }.merge! opts
      res = send_request :post, req, params
      obj = JSON.parse res.content
      Stella.ld "CREATED TRUN: #{obj.inspect}"
      @runid = obj['digest']
    end
    def testrun_log(sls)
      raise NoTestrunSelected, "no testrun: #{runid}" unless @runid
      req = uri('v1', 'testrun', "log.json")
      params = {
        :runid => @runid,
        :data => sls.to_json
      }
      res = send_request :post, req, params
      obj = JSON.parse res.content
      Stella.ld "LOGGED: #{obj.inspect}"
      @runid
    end
    def testrun_summary(summary)
      raise NoTestrunSelected unless @runid
      req = uri('v1', 'testrun', "summary.json")
      params = {
        :runid => @runid,
        :data => summary.to_json
      }
      res = send_request :post, req, params
      obj = JSON.parse res.content
      Stella.ld "CREATED SUMMARY: #{obj.inspect}"
      @runid
    end
    def client_create(clientid, opts={})
      raise NoTestrunSelected unless @runid
      req = uri('v1', 'client', "create.json")
      params = {
        :runid  => @runid,
        :clientid  => clientid
      }.merge! opts
      res = send_request :post, req, params
      obj = JSON.parse res.content
      @rtid = obj['digest']
    end
    def client_log(clientid, data, opts={})
      raise NoTestrunSelected unless @runid
      req = uri('v1', 'client', clientid, 'log.json')
      params = {
        :data => data
      }.merge! opts
      res = send_request :post, req, params
      obj = JSON.parse res.content
      Stella.ld "LOGGED: #{obj.inspect}"
      obj
    end
    # Returns true if the testplan was created. 
    # Otherwise false if it already exists.
    def testplan_sync(plan)
      if testplan? plan.digest
        @tid = plan.digest
        return false 
      end
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
          request_create props[:uri], props
        end
      end
      true
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
  
  attr_accessor :tid, :uid, :rtid, :runid
  
  def initialize(source=nil,apikey=nil)
    source ||= ENV['STELLA_SOURCE']
    apikey ||= ENV['STELLA_TOKEN']
    @source, @apikey = source, apikey
    @proxy = OpenStruct.new
    @http_client = create_http_client
    raise Stella::Error, "Set STELLA_SOURCE" unless @source
    raise Stella::Error, "Set STELLA_TOKEN" unless @apikey
  end
  
  def uri(*parts)
    uri = URI.parse @source
    uri.path = '/stella/' << parts.join( '/')
    Stella.ld "SERVICE URI: #{uri}"
    uri
  end
  
  def send_request(meth, uri, params={}, headers={})
    headers['X-TOKEN'] ||= @apikey

    params = process_params(params)

    if meth == "delete"
      args = [meth, uri, headers]
    else
      args = [meth, uri, params, headers]
    end
    res = @http_client.send(*args) # booya!
    
    if res.status > 200
      puts res.content
      raise Problem.new(res) 
    end
    
    res
  end
  
  private
    # Turn nested Hashes into: "key[name][1]" etc...
    def process_params(raw={})
      cooked = {}
      raw.each_pair do |k,v|
        cooked.merge!(process_enumerable(k, v)) and next if Enumerable === v
        cooked[k] = v
      end
      cooked
    end
    
    def process_enumerable(k,v)
      cooked = {}
      case v.class.to_s
      when "Array"
        v.each_with_index do |v2,index|
          name = "#{k}[#{index}]"
          cooked[name] = Enumerable === v2 ? process_enumerable(name, v2) : v2
        end
      when "Hash"
        v.each_pair do |k2,v2|
          name = "#{k}[#{k2}]"
          cooked[name] = Enumerable === v2 ? process_enumerable(name, v2) : v2
        end
      end
      cooked
    end
    
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

