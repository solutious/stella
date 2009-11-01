
STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__) unless defined?(STELLA_LIB_HOME)

#%w{attic hexoid storable sysinfo gibbler benelux}.each do |dir|
#  $:.unshift File.join(STELLA_LIB_HOME, '..', '..', dir, 'lib')
#end

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
  extend self
  
  START_TIME = Time.now.freeze
  
  SLEEP_METRICS = {
    :create_thread     => 0.001,
    :check_threads     => 0.0005
  }.freeze unless defined?(SLEEP_METRICS)
  
  def sleep(metric)
    unless SLEEP_METRICS.has_key? metric
      raise "unknown sleep metric: #{metric}" 
    end
    Kernel.sleep SLEEP_METRICS[metric]
  end
  
  # Puts +msg+ to +@logger+
  def lflush; log.flush if log.respond_to? :flush; end
  def li(*msg); msg.each { |m| log.puts m } if !log.quiet? end
  def li1(*msg); li *msg if log.lev >= 1 end
  def li2(*msg); li *msg if log.lev >= 2 end
  def li3(*msg); li *msg if log.lev >= 3 end
  def li4(*msg); li *msg if log.lev >= 4 end
  
  # Puts +msg+ to +@logger+ with "ERROR: " prepended
  def le(*msg); log.puts "  " << msg.join("#{$/}  ").color(:red); end
  # Puts +msg+ to +@logger+ if +Rudy.debug?+ returns true
  def ld(*msg)
    if debug?
      @log.puts "D(#{Thread.current.object_id}):  " << msg.join("#{$/}D:  ")
      Stella.lflush
    end
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
  
  def rescue(&blk)
    blk.call
  rescue => ex
    Stella.le "ERROR: #{ex.message}"
    Stella.li3 ex.backtrace
  end
  
  require 'stella/exceptions'
  require 'stella/mixins'
  
  autoload :VERSION, 'stella/version'
  autoload :Utils, 'stella/utils'
  autoload :Config, 'stella/config'
  autoload :Data, 'stella/data'
  autoload :Testplan, 'stella/testplan'
  autoload :Engine, 'stella/engine'
  autoload :Client, 'stella/client'
  
  @sysinfo = nil
  @log     = Stella::Data::Logger
  @debug   = false
  @abort   = false
  @datalogger = nil
  
  class << self
    attr_accessor :log
    attr_accessor :datalogger
  end
  
end




