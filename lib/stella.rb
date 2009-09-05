require 'gibbler'
require 'gibbler/aliases'
require 'storable'
require 'sysinfo'

unless defined?(STELLA_LIB_HOME)
  STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__)
end

module Stella
  autoload :Error, STELLA_LIB_HOME + "/stella/exceptions"
  
  @@sysinfo = SysInfo.new.freeze
  
  @@logger = STDERR
  @@loglev = 1
  
  module VERSION #:nodoc:
    unless defined?(MAJOR)
      MAJOR = 0.freeze
      MINOR = 7.freeze
      TINY  = 0.freeze
      PATCH = '001'.freeze
    end
    def self.to_s; [MAJOR, MINOR, TINY].join('.'); end
    def self.to_f; self.to_s.to_f; end
    def self.patch; PATCH; end
  end
  
  # Puts +msg+ to +@@logger+
  def self.li(*msg); msg.each { |m| @@logger.puts m } if !quiet? end
  # Puts +msg+ to +@@logger+ with "ERROR: " prepended
  def self.le(*msg); @@logger.puts "  " << msg.join("#{$/}  "); end
  # Puts +msg+ to +@@logger+ if +Rudy.debug?+ returns true
  def self.ld(*msg)
    @@logger.puts "D:  " << msg.join("#{$/}D:  ") if debug?
  end
  
  def self.loglev; @@loglev; end
  def self.sysinfo; @@sysinfo; end
  
  def self.quiet?; @@loglev == 0; end
  def self.enable_quiet; @@loglev = 0; end
  def self.disable_quiet; @@loglev = 1; end

  def self.debug?; @@loglev > 3; end
  def self.enable_debug; @@loglev = 4; end
  def self.disable_debug; @@loglev = 1; end
  
end

