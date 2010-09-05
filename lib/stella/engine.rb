
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
        opts = parse_opts testrun.options, opts
        threads = []
        testrun.stime = Stella.now
        testrun.running!
        opts[:concurrency].times do 
          threads << Thread.new do
            client = Stella::Client.new testrun.options
            Benelux.current_track "client_#{client.clientid.shorten}"
            begin
              opts[:repetitions].times do |idx|
                Stella.li '%-61s %s' % [testrun.plan.desc, testrun.plan.id.short]
                testrun.plan.usecases.each_with_index do |uc,i|
                  Benelux.current_track.add_tags :usecase => uc.id
                  Stella.rescue { 
                    Stella.li ' %-60s %s' % [uc.desc, uc.id.short]
                    client.execute uc do |session|
                      Stella.li '  %-63s %d' % [session.uri, session.status]
                    end
                  }
                  Benelux.current_track.remove_tags :usecase
                end
              end
            rescue Interrupt
              Stella.li "Skipping..."
            rescue => ex
              Stella.li ex.message
              Stella.li ex.backtrace if Stella.debug?
            end
          end
        end
        
        begin
          threads.each { |thread| thread.join }
          timeline = Benelux.merge_tracks
        rescue Interrupt
          puts "Skipping..."
        end
        
        begin
          testrun.etime = Stella.now
          testrun.report = Stella::Report.new timeline
          testrun.report.process
          testrun.done!
        rescue Interrupt
          puts "Exiting..."
          exit 1
        rescue => ex
          puts ex.message
          puts ex.backtrace if Stella.debug?
          testrun.etime = Stella.now
          testrun.fubar!
        end
        testrun.report
      end

      private 
      def parse_opts(runopts, opts)
        runopts[:repetitions] ||= (runopts['repetitions'] || 1).to_i
        runopts[:concurrency] ||= (runopts['concurrency'] || 1).to_i
        runopts[:wait] ||= (runopts['wait'] || 1).to_i
        runopts.merge opts
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