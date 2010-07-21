require 'em-http'

class Stella
  module Engine
    @modes = {}
    class << self
      attr_reader :modes
      def mode?(name)
        @mode.has_key? name
      end
      def load(name)
        @modes[name]
      end
    end
    module Base
      def self.included(obj)
        obj.extend ClassMethods
      end
      module ClassMethods
        attr_reader :mode
          def register(mode)
          @mode = mode
          Stella::Engine.modes[mode] = self
        end
        def run *args
          raise StellaError, "Must override run"
        end
      end
    end
    
  end
end

class Stella
  module Engine
    module Checkup
      include Engine::Base
      extend self
      def run testrun, options={}
        EM.run {
          client = Stella::Client.new
          testrun.start_time!
          testrun.plan.usecases.each_with_index do |uc,i|
            Stella.rescue { client.execute uc }
          end

          EventMachine.add_timer(1) {
            p 1
          }
        }
      end
      register :checkup
    end
  end
end