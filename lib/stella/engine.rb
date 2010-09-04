
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
      def run testrun, opts={}
        reps = (testrun.options[:repetitions] || testrun.options['repetitions'] || 1).to_i
        conc = (testrun.options[:concurrency] || testrun.options['concurrency'] || 1).to_i
        threads = []
        
        testrun.stime = Stella.now
        testrun.running!
        conc.times do 
          threads << Thread.new do |thread|
            client = Stella::Client.new testrun.options
            Benelux.current_track "client#{client.gibbler.shorten}"
            begin
              reps.times do |idx|
                testrun.plan.usecases.each_with_index do |uc,i|
                  Benelux.current_track.add_tags :usecase => uc.id
                  Stella.rescue { client.execute uc }
                  Benelux.current_track.remove_tags :usecase
                end
              end
            rescue => ex
              puts ex.message
              puts ex.backtrace if Stella.debug?
              testrun.etime = Stella.now
              testrun.fubar!
            end
          end
        end
        threads.each { |thread| thread.join }
        timeline = Benelux.merge_tracks
        p Benelux.tracks.keys
        begin
          testrun.etime = Stella.now
          testrun.report = Stella::Report.new timeline
          testrun.report.process
          testrun.done!
        rescue => ex
          puts ex.message
          puts ex.backtrace if Stella.debug?
          testrun.etime = Stella.now
          testrun.fubar!
        end
        testrun.report
      end

      Benelux.add_timer          HTTPClient, :do_request, :response_time
      Benelux.add_timer HTTPClient::Session, :connect, :socket_connect
      Benelux.add_timer HTTPClient::Session, :send_request, :send_request
      Benelux.add_timer HTTPClient::Session, :socket_gets_first_byte, :first_byte
      Benelux.add_timer HTTPClient::Session, :get_body, :last_byte
      
      register :checkup
    end
    
  end

end