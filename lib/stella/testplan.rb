

module Stella
  class Testplan < Storable
    include Gibbler::Complex
    extend Attic
    
    field :desc => String
    
    
    def initialize(desc=nil)
      
    end
    
    def self.load_file(path)
      raise Stella::Error, "Bad path: #{path}" unless File.exists?(path)
    end
    
    
    def check!
    end
    
    def freeze
    end
    
  end
end