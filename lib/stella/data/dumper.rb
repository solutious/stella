

module Stella
  module Data
    
    class BaseLogger
      attr_accessor :lev
      
      def initialize(output=STDOUT)
        @output = output
        @mutex, @buffer = Mutex.new, StringIO.new
        @lev, @offset = 0, 1
      end
    
      def flush
        @mutex.synchronize do
          #return if @offset == @output.tell
          @buffer.seek @offset
          @output.puts @buffer.read unless @buffer.eof?
          @offset = @buffer.tell
        end
      end
      
      def quiet?()        @lev == 0    end
      def enable_quiet()  @lev =  0    end
      def disable_quiet() @lev =  1    end
    
    end
    
    class SyncLogger < BaseLogger
      def print_sync(level, *msg)
        return unless level <= @lev
        @mutex.synchronize { @buffer.print *msg }
      end

      def puts_sync(level, *msg)
        return unless level <= @lev
        @mutex.synchronize { @buffer.puts *msg }
      end
    end
    
    class Logger < BaseLogger
      def print(level, *msg)
        return unless level <= @lev
        @buffer.print *msg
      end

      def puts(level, *msg)
        return unless level <= @lev
        @buffer.puts *msg
      end
    end
    
    module Dumper
      FREQUENCY = Stella::Engine::LoadQueue::ROTATE_TIMELINE * 4
      
      class << self
        @force_stop = false
        
        attr_reader :dthread
        
        def stop()  
          @force_stop = true  
          @dthread.join
        end
        def stop?() @force_stop == true end
        
        def start
          
          @dthread = Thread.new do
            prev_ptime = Time.now
            loop do
              break if Stella.abort?
              break if stop?
              if (Time.now - prev_ptime).to_i >= FREQUENCY
                Benelux.update_global_timeline
                Stella.li $/, [:logger, (Time.now - prev_ptime).to_i, Benelux.timeline.size].inspect
                prev_ptime = Time.now
                #p Benelux.timeline
                #Stella.datalogger.write
              end
              sleep FREQUENCY / 2
            end

          end
        end
        
        def log_dir(file=nil)
          stamp = Stella::START_TIME.strftime("%Y%m%d-%H:%M:%S")
          l = File.join Stella::Config.project_dir, 'log', stamp
          l = File.join l, file unless file.nil?
          l
        end 
        
        private

      end
      
    end
  end
end