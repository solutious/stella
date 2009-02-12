

module Stella
  module TestRunner
    attr_accessor :name
      # Name or instance of the testplan to execute
    attr_accessor :testplan
      # Determines the amount of output. Default: 0
    attr_accessor :verbose
    
    def initialize(name=:default)
      @name = name
      @verbose = 0
    end
    

    
  end
end
  
  
