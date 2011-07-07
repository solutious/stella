# encoding: utf-8
STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__) unless defined?(STELLA_LIB_HOME)

if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

require 'bundler/setup'
$:.unshift STELLA_LIB_HOME

%w{tryouts benelux storable gibbler familia bluth}.each do |dir|
  $:.unshift File.join(STELLA_LIB_HOME, '..', '..', dir, 'lib')
end

require 'yajl'
require 'httparty'
require 'storable'
require 'benelux'
require 'gibbler/aliases'
require 'stella/core_ext'
require 'familia'

autoload :Nokogiri, 'nokogiri'

class Stella
  module VERSION
    def self.to_s
      load_config
      [@version[:MAJOR], @version[:MINOR], @version[:PATCH]].join('.')
    end
    def self.inspect
      load_config
      [@version[:MAJOR], @version[:MINOR], @version[:PATCH], @version[:BUILD]].join('.')
    end
    def self.load_config
      require 'yaml'
      @version ||= YAML.load_file(File.join(STELLA_LIB_HOME, '..', 'VERSION.yml'))
    end
  end
end

#
# Any object that wants to be serialized to JSON 
# ought to inherit from this class. 
# 
# NOTE: you cannot define Storable fields here.
# Most notably, you'll prob want to include this. 
#
#   field :id, :class => Gibbler::Digest, :meth => :gibbler, &gibbler_id_processor
#
#module StellaObject < Storable
#  include Gibbler::Complex
#  def id
#    @id ||= self.digest
#    @id
#  end
#end

# All errors inherit from this class. 
class StellaError < RuntimeError
  def initialize(msg)
    @message = msg
  end
  attr_reader :message
end

class StellaBehavior < Exception
  def initialize(msg)
    @message = msg
  end
  attr_reader :message
end

class Stella
  class ForcedRedirect < StellaBehavior
    attr_accessor :location
    def initialize(l)
      @location = l
    end
  end
  class RepeatRequest < StellaBehavior
  end
  class UsecaseFail < StellaBehavior
  end
  class TestplanQuit < StellaBehavior
  end
  class RequestError < StellaBehavior
  end
  class TimeoutError < StellaError
  end
  class UsecaseError < StellaError
  end
  class PageError < StellaError
  end
  class HTTPError < StellaError
    attr_reader :status
    def initialize(status)
      @status = status
    end
    def message
      "#{status} error"
    end
  end
  require 'stella/utils'
  require 'stella/client'
  require 'stella/engine'
  require 'stella/report'
  require 'stella/testplan'
  attr_reader :plan
  def initialize *args
    @plan = Stella::TP === args.first ? 
      args.first.clone : Stella::TP.new(args.first)
    #@plan.freeze
    @runner
  end
end 


class Stella
  @sysinfo = nil
  @debug   = false
  @noise   = 1
  @abort   = false
  @quiet   = false
  @agent   = "Mozilla/5.0 (compatible; Stella/#{Stella::VERSION}; +http://solutious.com/projects/stella)"  
  # static methods
  class << self
    attr_accessor :log, :stdout, :agent, :debug, :quiet, :noise
    def debug?()        @debug == true  end
    def quiet?()        @quiet == true  end
    def li(*msg) STDERR.puts *msg unless quiet? end
    def le(*msg); li "  " << msg.join("#{$/}  ") end
    def ld(*msg)
      return unless Stella.debug?
      prefix = "D(#{Thread.current.object_id}):  "
      li("#{prefix}#{msg.join("#{$/}#{prefix}")}")
    end
    
    def get(uri, opts={})
      opts[:concurrency] ||= 1
      opts[:repetitions] ||= 1
      run = checkup uri, opts
      report = run.report
      if report.processed? && report.content && report.statuses.success?
        report.content.response_body 
      else
        nil
      end
    end
    def checkup(uri, opts={})
      plan = Stella::Testplan.new uri
      run = Stella::Testrun.new plan, :checkup, opts
      Stella::Engine.run run
      run
    end
    def now
      Time.now.utc.to_f
    end
    # http://blamestella.com/ => blamestella.com
    # https://blamestella.com/ => blamestella.com:443
    def canonical_host(host)
      return nil if host.nil?
      if host.kind_of?(URI)
        uri = host
      else
        host &&= host.to_s
        host.strip!
        host = host.to_s unless String === host
        host = "http://#{host}" unless host.match(/^https?:\/\//)
        uri = URI.parse(host)
      end
      str = "#{uri.host}".downcase 
      #str << ":#{uri.port}" if uri.port && uri.port != 80 
      str
    end
  
    def canonical_uri(uri)
      return nil if uri.nil?
      if uri.kind_of?(URI)
        uri = Addressable::URI.parse uri.to_s
      elsif uri.kind_of?(String)
        uri &&= uri.to_s
        uri.strip! unless uri.frozen?
        uri = "http://#{uri}" unless uri.match(/^https?:\/\//)
        uri = Addressable::URI.parse(uri)
      end
      uri.scheme ||= 'http'
      uri.path = '/' if uri.path.to_s.empty?
      uri
    end
    
    def rescue(&blk)
      blk.call
    rescue StellaError => ex
      Stella.le ex.message
      Stella.ld ex.backtrace
    #rescue => ex
    #  Stella.le ex.message
    #  Stella.le ex.backtrace
    end
    
  end
end

class Stella  
  class API
    include HTTParty
    ssl_ca_file Stella::Client::SSL_CERT_PATH
    format :json
    attr_reader :httparty_opts, :response, :account, :key
    def initialize account=nil, key=nil, httparty_opts={}
      self.class.base_uri ENV['STELLA_HOST'] || 'https://www.blamestella.com/api/v2'
      @httparty_opts = httparty_opts
      @account = account || ENV['STELLA_ACCOUNT']
      @key = key || ENV['STELLA_KEY']
      unless @account.to_s.empty? || @key.to_s.empty?
        httparty_opts[:basic_auth] ||= { :username => @account, :password => @key }
      end
    end
    def get path, params=nil
      opts = httparty_opts
      opts[:query] = params || {}
      execute_request :get, path, opts
    end
    def post path, params=nil
      opts = httparty_opts
      opts[:body] = params || {}
      execute_request :post, path, opts
    end
    def site_uri path
      uri = Addressable::URI.parse self.class.base_uri
      uri.path = uri_path(path)
      uri.to_s
    end
    private
    def uri_path *args
      args.unshift ''  # force leading slash
      path = args.flatten.join('/')
      path.gsub '//', '/'
    end
    def execute_request meth, path, opts
      path = uri_path [path]
      @response = self.class.send meth, path, opts
      indifferent_params @response.parsed_response
    end
    # Enable string or symbol key access to the nested params hash.
    def indifferent_params(params)
      if params.is_a?(Hash)
        params = indifferent_hash.merge(params)
        params.each do |key, value|
          next unless value.is_a?(Hash) || value.is_a?(Array)
          params[key] = indifferent_params(value)
        end
      elsif params.is_a?(Array)
        params.collect! do |value|
          if value.is_a?(Hash) || value.is_a?(Array)
            indifferent_params(value)
          else
            value
          end
        end
      end
    end
    # Creates a Hash with indifferent access.
    def indifferent_hash
      Hash.new {|hash,key| hash[key.to_s] if Symbol === key }
    end
    
    class Unauthorized < RuntimeError
    end
  end
end


