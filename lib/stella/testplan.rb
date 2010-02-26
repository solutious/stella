

module Stella
  class Testplan < Storable
    include Gibbler::Complex
    extend Attic
    
    attic :base_path
    attic :plan_path
    attic :desc  # don't include in digest
    
    field :id, &gibbler_id_processor
    field :desc => String
    field :usecases => Array

    def initialize(desc=nil)
      
    end
    
    def self.load_file(path)
      raise Stella::Error, "Bad path: #{path}" unless File.exists?(path)
      plan = Stella::Testplan.new
      plan
    end
    
    
    def check!
    end
    
    def freeze
    end
    
  end
end