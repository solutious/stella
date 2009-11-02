
STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__) unless defined?(STELLA_LIB_HOME)

%w{attic hexoid storable sysinfo gibbler benelux}.each do |dir|
  $:.unshift File.join(STELLA_LIB_HOME, '..', '..', dir, 'lib')
end

autoload :SysInfo, 'sysinfo'
autoload :Drydock, 'drydock'
autoload :URI, 'uri'
autoload :OpenStruct, 'ostruct'
autoload :Storable, 'storable'
autoload :Gibbler, 'gibbler/aliases'
autoload :Attic, 'attic'
autoload :ERB, 'erb'

require 'benelux'

module Stella
  module VERSION
    unless defined?(MAJOR)
      MAJOR = 0.freeze
      MINOR = 7.freeze
      TINY  = 3.freeze
      PATCH = '002'.freeze 
    end
    def self.to_s; [MAJOR, MINOR, TINY].join('.'); end
    def self.to_f; self.to_s.to_f; end
    def self.patch; PATCH; end
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
  class NoHostDefined < Stella::Error; end
end


module Stella
  extend self
  
  require 'stella/logger'
  
  START_TIME = Time.now.freeze
  
  
  @sysinfo = nil
  @debug   = false
  @abort   = false
  @quiet   = false
  @log     = Stella::SyncLogger.new
  @stdout  = Stella::Logger.new STDOUT
    
  class << self
    attr_accessor :log, :stdout
  end

  def le(*msg); stdout.info "  " << msg.join("#{$/}  ").color(:red); end
  def ld(*msg)
    return unless Stella.debug?
    Stella.stdout.info "D(#{Thread.current.object_id}):  " << msg.join("#{$/}D:  ")
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
  def enable_quiet()  @quiet = true   end
  def disable_quiet() @quiet = false  end
    
  def rescue(&blk)
    blk.call
  rescue => ex
    Stella.stdout.info "ERROR: #{ex.message}"
    Stella.stdout.info ex.backtrace
  end
  
  require 'stella/common'
  
  autoload :Utils, 'stella/utils'
  autoload :Config, 'stella/config'
  autoload :Data, 'stella/data'
  autoload :Testplan, 'stella/testplan'
  autoload :Engine, 'stella/engine'
  autoload :Client, 'stella/client'
  
end

Stella.stdout.lev = Stella.quiet? ? 0 : 1
Stella.stdout.autoflush!





