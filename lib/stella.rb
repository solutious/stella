
require 'date'
require 'time'
require 'rubygems'


# Common dependencies
$: << File.join(STELLA_HOME, 'vendor', 'useragent', 'lib')
require 'user_agent'

#  A friend in performance testing. 
module Stella 

  LOGGER = Stella::Logger.new(:debug=>true) unless defined? LOGGER
  
  module VERSION #:nodoc:
    MAJOR = 0.freeze unless defined? MAJOR
    MINOR = 5.freeze unless defined? MINOR
    TINY  = 5.freeze unless defined? TINY
    def self.to_s
      [MAJOR, MINOR, TINY].join('.')
    end
    def self.to_f
      self.to_s.to_f
    end
  end
  
  def self.debug
    Stella::LOGGER.debug_level
  end
  
  def self.debug=(enable)
    Stella::LOGGER.debug_level = enable
  end
  
  def self.text(*args)
    TEXT.msg(*args)
  end
  
  def self.sysinfo
    SYSINFO
  end
  
  def self.info(*args)
    LOGGER.info(*args)
  end
  
  def self.error(*args)
    LOGGER.error(*args)
  end
  
end

