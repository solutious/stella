
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

  module Engine
    module Checkup
      include Engine::Base
      extend self
      def run testrun, options={}
        
        thread = Thread.new do
          # Identify this thread to Benelux
          Benelux.current_track :functional
          client = Stella::Client.new
          testrun.start_time!
          testrun.plan.usecases.each_with_index do |uc,i|
            Stella.rescue { client.execute uc }
          end
        end
        thread.join
        
        p thread.timeline
      end

      Benelux.add_timer          HTTPClient, :do_request, :response_time
      Benelux.add_timer HTTPClient::Session, :connect, :socket_connect
      Benelux.add_timer HTTPClient::Session, :query, :send_request
      Benelux.add_timer HTTPClient::Session, :socket_gets_first_byte, :first_byte
      Benelux.add_timer HTTPClient::Session, :get_body, :receive_response
      
      register :checkup
    end
    
  end

end