
require 'date'
require 'time'
require 'rubygems'

require 'logger'

require 'stella/testplan'
require 'stella/loadtest'

# Common dependencies
STELLA_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$: << File.join(STELLA_HOME, 'vendor', 'useragent', 'lib')
require 'user_agent'

#  A friend in performance testing. 
module Stella 

  LOGGER = Logger.new(:debug_level=>0) unless defined? LOGGER
  
  module VERSION #:nodoc:
    MAJOR = 0.freeze unless defined? MAJOR
    MINOR = 6.freeze unless defined? MINOR
    TINY  = 0.freeze unless defined? TINY
    def self.to_s
      [MAJOR, MINOR, TINY].join('.')
    end
    def self.to_f
      self.to_s.to_f
    end
  end
  
  def self.debug_level
    Stella::LOGGER.debug_level
  end
  
  def self.debug_level=(level)
    Stella::LOGGER.debug_level = level
  end
  
  def self.info(*args)
    LOGGER.info(*args)
  end
  
  def self.error(*args)
    LOGGER.error(*args)
  end
  
  def self.fatal(*args)
    LOGGER.error(*args)
    exit 1
  end
  
  def self.debug(*args)
    LOGGER.debug(*args)
  end
end

