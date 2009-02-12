
require 'date'
require 'time'
require 'rubygems'

require 'logger'

require 'uri'
require 'httpclient'

require 'storable'

require 'stella/data/http'
require 'stella/data/domain'

require 'stella/testrunner'
require 'stella/testplan'
require 'stella/loadtest'
require 'stella/functest'

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

class Object #:nodoc: all
# The hidden singleton lurks behind everyone
   def metaclass; class << self; self; end; end
   def meta_eval &blk; metaclass.instance_eval &blk; end

   # Adds methods to a metaclass
   def meta_def name, &blk
     meta_eval { define_method name, &blk }
   end

   # Defines an instance method within a class
   def class_def name, &blk
     class_eval { define_method name, &blk }
   end

end
  