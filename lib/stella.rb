#--
# http://rdoc.sourceforge.net/doc/files/README.html
# ++

require 'date'
require 'time'
require 'tempfile'
require 'socket'
require 'ostruct'
require 'optparse'
require 'rubygems'


# Common utilities
require 'utils/domainutil'
require 'utils/httputil'
require 'utils/fileutil'
require 'utils/mathutil'
require 'utils/escape'
require 'utils/stats'

# Common dependencies
$: << File.join(STELLA_HOME, 'vendor', 'useragent', 'lib')
require 'user_agent'

# Common Stella dependencies
require 'stella/support'
require 'stella/storable'

# Common Stella Data Objects
require 'stella/data/http'
require 'stella/data/domain'

# Common Stella objects
require 'stella/text'

require 'stella/logger'
require 'stella/response'
require 'stella/sysinfo'
require 'stella/test/definition'
require 'stella/test/run/summary'
require 'stella/test/stats'

# Commands
require 'stella/command/base'
require 'stella/command/localtest'
require 'stella/command/watch'

# Adapters
require 'stella/adapter/base'
require 'stella/adapter/ab'
require 'stella/adapter/siege'
require 'stella/adapter/httperf'
require 'stella/adapter/proxy'

#  A friend in performance testing. 
#
# This class ties Stella together. It must be required because it defines
# several constants which are used througout the other classes. +SYSINFO+ 
# is particularly important because it detects the platform and requires
# platform specific modules. 
module Stella 
    # Autodetecets information about the local system, 
    # including OS (unix), implementation (freebsd), and architecture (x64)
  SYSINFO = Stella::SystemInfo.new unless defined? SYSINFO
    # A global logger for info, error, and debug messages. 
  LOGGER = Stella::Logger.new(:debug=>true) unless defined? LOGGER
    # A global resource for all interface text. 
  TEXT = Stella::Text.new('en') unless defined? TEXT
  
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

