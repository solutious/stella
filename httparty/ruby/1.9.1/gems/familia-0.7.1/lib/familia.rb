# encoding: utf-8
FAMILIA_LIB_HOME = File.expand_path File.dirname(__FILE__) unless defined?(FAMILIA_LIB_HOME)
require 'uri/redis'
require 'gibbler'
require 'familia/core_ext'
require 'multi_json'

module Familia
  module VERSION
    def self.to_s
      load_config
      [@version[:MAJOR], @version[:MINOR], @version[:PATCH]].join('.')
    end
    alias_method :inspect, :to_s
    def self.load_config
      require 'yaml'
      @version ||= YAML.load_file(File.join(FAMILIA_LIB_HOME, '..', 'VERSION.yml'))
    end
  end
end

module Familia
  include Gibbler::Complex
  @secret = '1-800-AWESOME' # Should be modified via Familia.secret = ''
  @apiversion = nil
  @uri = URI.parse 'redis://127.0.0.1'
  @delim = ':'
  @clients = {}
  @classes = []
  @suffix = :object.freeze
  @index = :id.freeze
  @debug = false
  @dump_method = :to_json
  @load_method = :from_json
  class << self
    attr_reader :clients, :uri, :logger
    attr_accessor :debug, :secret, :delim, :dump_method, :load_method
    attr_writer :apiversion
    def debug?() @debug == true end
    def info *msg
      STDERR.puts *msg
    end
    def classes with_redis_objects=false
      with_redis_objects ? [@classes, RedisObject.classes].flatten : @classes
    end
    def ld *msg
      info *msg if debug?
    end
    def trace label, redis_client, ident, context=nil
      return unless Familia.debug?
      info "[%s] %s/%s" % [label, redis_client.uri, ident] 
      if context
        context = [context].flatten
        context.reject! { |line| line =~ /lib\/familia/ }
        info "   %s" % context[0..6].join("\n   ") 
      end
    end
    def uri= v
      v = URI.parse v unless URI === v
      @uri = v
    end
    # A convenience method for returning the appropriate Redis
    # connection. If +uri+ is an Integer, we'll treat it as a
    # database number. If it's a String, we'll treat it as a 
    # full URI (e.g. redis://1.2.3.4/15).
    # Otherwise we'll return the default connection. 
    def redis(uri=nil)
      if Integer === uri
        tmp = Familia.uri
        tmp.db = uri
        uri = tmp
      elsif String === uri
        uri &&= URI.parse uri
      end
      uri ||= Familia.uri
      connect(uri) unless @clients[uri.serverid] 
      @clients[uri.serverid]
    end
    def log(level, path)
      logger = Log4r::Logger.new('familia')
      logger.outputters = Log4r::FileOutputter.new 'familia', :filename => path
      logger.level = Log4r.const_get(level)
      logger
    end
    def connect(uri=nil)
      uri &&= URI.parse uri if String === uri
      uri ||= Familia.uri
      conf = uri.conf
      conf[:thread_safe] = "true" unless conf.has_key?(:thread_safe)
      conf[:thread_safe] = conf[:thread_safe].to_s == "true"
      conf[:logging] = conf[:logging].to_s == "true"
      if conf.has_key?(:logging) && conf[:logging].to_s == "true"
        require 'logger'
        require 'log4r'
        @logger ||= log :DEBUG, "./familia.log"
        conf[:logger] = Familia.logger
      end
      redis = Redis.new conf
      Familia.trace :CONNECT, redis, conf.inspect, caller[0..3] if Familia.debug
      @clients[uri.serverid] = redis
    end
    def reconnect_all!
      Familia.classes.each do |klass|
        klass.redis.client.reconnect
        Familia.info "#{klass} ping: #{klass.redis.ping}" if debug?
      end
    end
    def connected?(uri=nil)
      uri &&= URI.parse uri if String === uri
      @clients.has_key?(uri.serverid)
    end
    def default_suffix(a=nil) @suffix = a if a; @suffix end
    def default_suffix=(a) @suffix = a end
    def index(r=nil)  @index = r if r; @index end
    def index=(r) @index = r; r end
    def join(*r) r.join(Familia.delim) end
    def split(r) r.split(Familia.delim) end
    def rediskey *args
      el = args.flatten.compact
      el.unshift @apiversion unless @apiversion.nil?
      el.join(Familia.delim)
    end
    def apiversion(r=nil, &blk)  
      if blk.nil?
        @apiversion = r if r; 
      else
        tmp = @apiversion
        @apiversion = r
        blk.call
        @apiversion = tmp
      end
      @apiversion 
    end
    def now n=Time.now
      n.utc.to_i
    end
    # A quantized timestamp
    # e.g. 12:32 -> 12:30
    # 
    def qnow quantum=10.minutes, now=Familia.now
      rounded = now - (now % quantum)
      Time.at(rounded).utc.to_i
    end
  end
  
  class Problem < RuntimeError; end
  class NoIndex < Problem; end
  class NonUniqueKey < Problem; end
  class NotConnected < Problem
    attr_reader :uri
    def initialize uri
      @uri = uri
    end
    def message
      "No client for #{uri.serverid}"
    end
  end
  
  def self.included(obj)
    obj.send :include, Familia::InstanceMethods
    obj.send :include, Gibbler::Complex
    obj.extend Familia::ClassMethods
    obj.class_zset :instances, :class => obj, :reference => true
    Familia.classes << obj
  end
  
  require 'familia/object'
  require 'familia/helpers'

end


module Familia
  module Collector
    def klasses
      @klasses ||= []
      @klasses
    end
    def included(obj)
      self.klasses << obj
    end
  end  
end
