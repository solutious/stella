require 'date'
require 'time'
require 'tempfile'
require 'socket'

# Common utilities
require 'utils/httputil'
require 'utils/fileutil'
require 'utils/mathutil'
require 'utils/escape'

# Common dependencies
$: << File.join(STELLA_HOME, 'vendor', 'useragent', 'lib')
require 'user_agent'

# Common Stella dependencies
require 'stella/support'
require 'stella/storable'

# Common Stella objects
require 'stella/text'
require 'stella/logger'
require 'stella/response'
require 'stella/sysinfo'
require 'stella/test/definition'
require 'stella/test/run/summary'
require 'stella/test/summary'

# Commands
require 'stella/command/base'
require 'stella/command/localtest'

# Adapters
require 'stella/adapter/base'
require 'stella/adapter/ab'
require 'stella/adapter/siege'
require 'stella/adapter/httperf'

# = Stella
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
    TINY  = 3.freeze unless defined? TINY
    def self.to_s
      [MAJOR, MINOR, TINY].join('.')
    end
    def self.to_f
      self.to_s.to_f
    end
  end


end

