

module Stella
  
  module TestRunner
    attr_accessor :name
      # Name or instance of the testplan to execute
    attr_accessor :testplan
    
    def initialize(name=:default)
      @name = name
    end
    

    
  end
end
  
  
