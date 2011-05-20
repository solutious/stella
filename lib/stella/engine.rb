
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
      def run testrun, opts={}
        case testrun.mode.to_sym
        when :checkup
          Stella::Engine::Checkup.run testrun, opts
        else
          Stella.le "Unknown Engine: #{testrun.mode}"
        end
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
      end
    end
  end

  module Engine
    module Checkup
      include Engine::Base
      extend self
      def run testrun, opts={}
        opts = parse_opts testrun.options, opts
        Stella.ld "testrun opts: #{opts.inspect}"
        threads = []
        testrun.stime = Stella.now
        testrun.running!
        opts[:concurrency].times do 
          threads << Thread.new do
            client = Stella::Client.new opts
            Benelux.current_track "client_#{client.clientid.shorten}"
            begin
              opts[:repetitions].times do |idx|
                Stella.li '%-61s %s' % [testrun.plan.desc, testrun.plan.planid.short] if Stella.noise >= 1
                testrun.plan.usecases.each_with_index do |uc,i|
                  if opts[:usecases].nil? || opts[:usecases].member?(uc.class)
                    Benelux.current_track.add_tags :usecase => uc.id
                    Stella.rescue { 
                      Stella.li ' %-60s %s' % [uc.desc, uc.id.short] if Stella.noise >= 1
                      client.execute uc do |session|
                        Stella.li '  %-76s %d' % [session.uri, session.status] if Stella.noise >= 1
                      end
                    }
                    if client.exception
                      Stella.li '   %s (%s)' % [client.exception.message, client.exception.class]
                      # TODO: use a throw. This won't stop the next repetition.
                      break if Stella::TestplanQuit === client.exception
                    end
                  else
                    Stella.li ' %-60s %s' % ["#{uc.desc} (skipped)", uc.id.short] if Stella.noise >= 1
                  end
                  Benelux.current_track.remove_tags :usecase
                end
              end
            rescue Interrupt
              Stella.li "Skipping..." 
              testrun.etime = Stella.now
              testrun.fubar!
              exit 1
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
          Stella.li "Skipping..."
          testrun.etime = Stella.now
          testrun.fubar!
          exit 1
        end
        
        begin
          testrun.etime = Stella.now
          testrun.report = Stella::Report.new timeline, testrun.runid
          testrun.report.process 
          testrun.report.fubars? ? testrun.fubar! : testrun.done! 
        rescue Interrupt
          Stella.li "Exiting..."
          testrun.etime = Stella.now
          testrun.fubar!
          exit 1
        rescue => ex
          Stella.li ex.message
          Stella.li ex.backtrace if Stella.debug?
          testrun.etime = Stella.now
          testrun.fubar!
        end
        Benelux.reset # If we run again, the old stats still remain
        testrun.report
      end

      private 
      def parse_opts(runopts, opts)
        runopts.keys.each do |key|
          runopts[key.to_sym] = runopts.delete(key) if String === key
        end
        opts.keys.each do |key|
          opts[key.to_sym] = opts.delete(key) if String === key
        end
        runopts[:repetitions] ||= 1
        runopts[:concurrency] ||= 1
        runopts[:wait] ||= 1
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