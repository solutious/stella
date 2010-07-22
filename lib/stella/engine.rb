
class Stella
  module Engine
    @modes = {}
    class << self
      attr_reader :modes
      def mode?(name)
        @modes.has_key? name
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
        reps = testrun.options.repetitions || 1
        
        thread = Thread.new do
          Benelux.current_track :checkup
          client = Stella::Client.new
          testrun.time_start!
          reps.times do |idx|
            testrun.plan.usecases.each_with_index do |uc,i|
              Benelux.add_thread_tags :usecase => uc.id
              Stella.rescue { client.execute uc }
              Benelux.remove_thread_tags :usecase
            end
          end
        end
        thread.join
        report = Stella::Report.new thread.timeline
        report.process
        report
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