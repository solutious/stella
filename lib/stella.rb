
STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__) unless defined?(STELLA_LIB_HOME)

%w{attic hexoid storable sysinfo gibbler benelux}.each do |dir|
  $:.unshift File.join(STELLA_LIB_HOME, '..', '..', dir, 'lib')
end

autoload :SysInfo, 'sysinfo'
autoload :Drydock, 'drydock'
autoload :URI, 'uri'
autoload :OpenStruct, 'ostruct'
autoload :Storable, 'storable'
autoload :Attic, 'attic'
autoload :ERB, 'erb'

require 'gibbler/aliases'  # important for run time digests and freezes
require 'benelux'
require 'proc_source'

module Stella
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

module Stella
  class Error < RuntimeError
    def initialize(obj=nil); @obj = obj; end
    def message; @obj; end
  end
  class WackyRatio < Stella::Error; end
  class WackyDuration < Stella::Error; end
  class InvalidOption < Stella::Error; end
  class NoHostDefined < Stella::Error
    def message; "No host specified for uri: #{@obj}"; end
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

module Stella
  extend self
  
  require 'stella/logger'
  
  unless defined?(START_TIME)
    START_TIME = Time.now.freeze
  end
  
  @globals = {}
  @sysinfo = nil
  @debug   = false
  @abort   = false
  @quiet   = false
  @log     = Stella::SyncLogger.new
  @stdout  = Stella::Logger.new STDOUT
    
  class << self
    attr_accessor :log, :stdout
  end
  
  def le(*msg); stdout.info "  " << msg.join("#{$/}  ").colour(:red); end
  def ld(*msg)
    return unless Stella.debug?
    prefix = "D(#{Thread.current.object_id}):  "
    Stella.stdout.info("#{prefix}#{msg.join("#{$/}#{prefix}")}".colour(:yellow))
  end
  
  def sysinfo
    @sysinfo = SysInfo.new.freeze if @sysinfo.nil?
    @sysinfo 
  end
  
  def debug?()        @debug == true  end
  def enable_debug()  @debug =  true  end
  def disable_debug() @debug =  false end
  
  def abort?()        @abort == true  end
  def abort!()        @abort =  true  end
  
  def quiet?()        @quiet == true  end
  def enable_quiet()  @quiet = true; Stella::Logger.disable!;  end
  def disable_quiet() @quiet = false; Stella::Logger.enable!;  end
  
  def add_global(n,v)
    Stella.ld "SETGLOBAL: #{n}=#{v}"
    @globals[n.strip] = v.strip
  end
  
  def rescue(&blk)
    blk.call
  rescue => ex
    Stella.le "ERROR: #{ex.message}"
    Stella.ld ex.backtrace
  end
  
  require 'stella/common'
  
  autoload :Utils, 'stella/utils'
  autoload :Config, 'stella/config'
  autoload :Data, 'stella/data'
  autoload :Testplan, 'stella/testplan'
  autoload :Testrun, 'stella/engine'
  autoload :Engine, 'stella/engine'
  autoload :Client, 'stella/client'
  autoload :Service, 'stella/service'
  
  def get(uri, query={})
    require 'stella/client'
    http_client = HTTPClient.new :agent_name => "Opera/9.51 (Windows NT 5.1; U; en)"
    http_client.get(uri, query).body.content
  rescue => ex
    STDERR.puts ex.message
    STDERR.puts ex.backtrace if Stella.debug?
    nil
  end
  
end

Stella.stdout.lev = Stella.quiet? ? 0 : 1
Stella.stdout.autoflush!



class Storable
  # These methods are used by Storable objects. 
  # See Stella::Testplan
  module DefaultProcessors
    # If the object already has a value for +@id+
    # use it, otherwise return the current digest.
    #
    # This allows an object to have a preset ID. 
    #
    def gibbler_id_processor
      Proc.new do |val|
        @id || self.gibbler
      end
    end
  end
end



