
require 'ostruct'
require 'threadify'

module Stella
  extend self

  LIB_HOME = File.expand_path File.dirname(__FILE__) unless defined?(LIB_HOME)
  
  %w{storable sysinfo gibbler benelux}.each do |dir|
    $:.unshift File.join(LIB_HOME, '..', '..', dir, 'lib')
  end
  require 'sysinfo'
  require 'drydock/screen'
  require 'storable'
  require 'gibbler'
  require 'gibbler/aliases'
  require 'benelux'
  
  @@sysinfo = SysInfo.new.freeze
  @@logger = Drydock::Screen
  @@loglev = 1
  @@debug  = false
  
  # Puts +msg+ to +@@logger+
  def lflush; @@logger.flush if @@logger.respond_to? :flush; end
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

  def debug?; @@debug == true; end
  def enable_debug; @@debug = true; end
  def disable_debug; @@debug = false; end
  
  def rescue(&blk)
    blk.call
  rescue => ex
    Stella.le "ERROR: #{ex.message}"
    Stella.ld ex.backtrace
  end
end

require 'stella/version'
require 'stella/exceptions'
require 'stella/utils'
require 'stella/config'
require 'stella/data'

Stella::Utils.require_vendor "httpclient", '2.1.5.2'
Stella::Utils.require_glob(Stella::LIB_HOME, 'stella', '*.rb')

