require 'uri'
require 'httpclient'
#require 'stella/loadtest/helpers'
require 'stella/loadtest/dsl'

module Stella
  
  # 
  # 
  # 
  class LoadTest
    attr_accessor :name
      # Name or instance of the testplan to execute
    attr_accessor :testplan
    attr_accessor :users
    attr_accessor :repetitions
    attr_accessor :duration
    
    def initialize(name=:default)
      @name = name
    end
    
    def run
      puts "Running Test: #{@name}"
    end
      
  end
end