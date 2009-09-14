
unless defined?(STELLA_LIB_HOME)
  STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__)
end

local_libs = %w{drydock storable sysinfo gibbler}
local_libs.each { |dir| $:.unshift File.join(STELLA_LIB_HOME, '..', '..', dir, 'lib') }
#require 'rubygems'

require 'storable'
require 'sysinfo'
require 'gibbler'
require 'gibbler/aliases'
require 'ostruct'
require 'threadify'
require 'drydock/screen'

module Stella
  extend self
  require 'stella/version'
  require 'stella/exceptions'
  require 'stella/utils'
  require 'stella/stats'
  require 'stella/mixins'
  require 'stella/dsl'
  require 'stella/engine'
  require 'stella/testplan'

  autoload :Utils, STELLA_LIB_HOME + "/stella/utils"
  autoload :Data, STELLA_LIB_HOME + "/stella/data"
  autoload :Config, STELLA_LIB_HOME + "/stella/config"
  autoload :Client, STELLA_LIB_HOME + "/stella/client"
  
  @@sysinfo = SysInfo.new.freeze
    
  @@logger = Drydock::Screen
  @@loglev = 1
  
  # Puts +msg+ to +@@logger+
  def li(*msg); msg.each { |m| @@logger.puts m } if !quiet? end
  def li1(*msg); li *msg if @@loglev >= 1 end
  def li2(*msg); li *msg if @@loglev >= 2 end
  def li3(*msg); li *msg if @@loglev >= 3 end
  def li4(*msg); li *msg if @@loglev >= 4 end
  
  # Puts +msg+ to +@@logger+ with "ERROR: " prepended
  def le(*msg); @@logger.puts "  " << msg.join("#{$/}  ").color(:red); end
  # Puts +msg+ to +@@logger+ if +Rudy.debug?+ returns true
  def ld(*msg)
    @@logger.puts "D:  " << msg.join("#{$/}D:  ") if debug?
  end
  
  def loglev; @@loglev; end
  def loglev=(val); @@loglev = val; end
  def sysinfo; @@sysinfo; end
  
  def quiet?; @@loglev == 0; end
  def enable_quiet; @@loglev = 0; end
  def disable_quiet; @@loglev = 1; end

  def debug?; @@loglev > 3; end
  def enable_debug; @@loglev = 4; end
  def disable_debug; @@loglev = 1; end
  
  def rescue(&blk)
    blk.call
  rescue => ex
    Stella.le "ERROR: #{ex.message}"
    Stella.ld ex.backtrace
  end
end

