STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__) unless defined?(STELLA_LIB_HOME)

%w{tryouts storable gibbler}.each do |dir|
  $:.unshift File.join(STELLA_LIB_HOME, '..', '..', dir, 'lib')
end

require 'erb'
require 'storable'
require 'benelux'
require 'gibbler/aliases'

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


class OpenStruct
  include Gibbler::Object
end

#
# Any object that wants to be serialized to JSON 
# ought to inherit from this class. 
# 
# NOTE: you cannot define Storable fields here.
# Most notably, you'll prob want to include this. 
#
#   field :id => Gibbler::Digest, &gibbler_id_processor
#
class StellaObject < Storable
  include Gibbler::Complex
  def id
    @id ||= self.digest
    @id
  end
end

# All errors inherit from this class. 
class StellaError < RuntimeError
end

class Stella
  require 'stella/utils'
  require 'stella/client'
  require 'stella/engine'
  require 'stella/report'
  require 'stella/metric'
  require 'stella/testplan'
  attr_reader :plan
  def initialize *args
    @plan = Stella::TP === args.first ? 
      args.first.clone : Stella::TP.new(args.first)
    @plan.freeze
    @runner
  end
end 


class Stella
  @sysinfo = nil
  @debug   = false
  @abort   = false
  @quiet   = false
  @agent   = "Stella/#{Stella::VERSION}"  
  # static methods
  class << self
    attr_accessor :log, :stdout, :agent, :debug, :quiet
    def debug?()        @debug == true  end
    def quiet?()        @quiet == true  end
    def li(*msg) STDOUT.puts *msg end
    def le(*msg); li "  " << msg.join("#{$/}  ") end
    def ld(*msg)
      return unless Stella.debug?
      prefix = "D(#{Thread.current.object_id}):  "
      li("#{prefix}#{msg.join("#{$/}#{prefix}")}")
    end
    
    def get(uri)
      uri
    end
    def checkup(uri)
      tplan = Stella::Testplan.new uri
      uri
    end
    def now
      Time.now.utc.to_f
    end
    # http://blamestella.com/ => blamestella.com
    # https://blamestella.com/ => blamestella.com:443
    def canonical_host(host)
      if host.kind_of?(URI)
        uri = host
      else
        host &&= host.to_s
        host.strip!
        host = host.to_s unless String === host
        host = "http://#{host}" unless host.match(/^https?:\/\//)
        uri = URI.parse(host)
      end
      str = "#{uri.host}"
      str << ":#{uri.port}" if uri.port && uri.port != 80 
      str.downcase
    end
  
    def rescue(&blk)
      blk.call
    rescue StellaError => ex
      Stella.le ex.message
      Stella.ld ex.backtrace
    rescue => ex
      Stella.le ex.message
      Stella.le ex.backtrace
    end
    
  end
end

class Stella::Template
  include Gibbler::String
  attr_reader :src
  def initialize(src)
    src = src.to_s
    @src, @template = src, ERB.new(src)
  end
  def result(binding)
    @template.result(binding)
  end
  def to_s() src end
end


