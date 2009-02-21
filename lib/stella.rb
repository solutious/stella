
require 'date'
require 'time'
require 'rubygems'
require 'logger'
require 'uri'
require 'httpclient'

require 'storable'
require 'stella/stats'
require 'threadify'
require 'timeunits'

require 'stella/crypto'

require 'stella/common'

require 'stella/data/http'
require 'stella/data/domain'

require 'stella/environment'
require 'stella/clients'
require 'stella/testrunner'
require 'stella/testplan'
require 'stella/loadtest'
require 'stella/functest'

srand

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

module Stella
  module DSL
    include Stella::DSL::TestPlan
    include Stella::DSL::FunctionalTest
    include Stella::DSL::LoadTest
    include Stella::DSL::Environment
    # For Modules
    #extend Stella::DSL::TestPlan
    #extend Stella::DSL::FunctionalTest
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

class Array
  # create a hash from an array of [key,value] tuples
  # you can set default or provide a block just as with Hash::new
  # Note: if you use [key, value1, value2, value#], hash[key] will
  # be [value1, value2, value#]
  # From: http://www.ruby-forum.com/topic/138218#615260
  def stella_to_hash(default=nil, &block)
    hash = block_given? ? Hash.new(&block) : Hash.new(default)
    each { |(key, *value)| hash[key]=*value }
    hash
  end
end
