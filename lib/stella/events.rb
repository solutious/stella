
module Stella
  module Events
    @loaded = false
    
    # Keep track of the support event types
    module EventType
      @klasses = []
      class << self
        attr_reader :klasses
      end
      def self.included(obj)
        @klasses << obj
      end
    end
    
    def self.loaded?() @loaded = true end
    def self.load
      EventType.klasses.each do |obj|
        dsl_klass = eval "#{obj}::DSL"
        Stella::Testplan::Usecase.module_eval do
          include dsl_klass
        end
      end
    end
    
    module EventTemplate
      
    end
    
    module EventAuth
    end
    
    
  end
end

Stella::Utils.require_glob 'stella/events/*'
