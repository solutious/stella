

module Stella
  module Data
    
    class Logger
      attr_accessor :lev
      
      def initialize(output=STDOUT)
        @mutex, @buffer = Mutex.new, StringIO.new
        @lev, @offset = 1, 0
        self.output = output
      end
      
      def print(level, *msg)
        return unless level <= @lev
        @buffer.print *msg
      end
      def puts(level, *msg)
        return unless level <= @lev
        @buffer.puts *msg
      end
      
      def output=(o)
        @mutex.synchronize do
          if o.kind_of? String
            o = File.open(o, File::CREAT|File::TRUNC|File::RDWR, 0644)
          end
          @output = o
        end
      end
      
      def flush
        @mutex.synchronize do
          #return if @offset == @output.tell
          @buffer.seek @offset
          @output.puts @buffer.read unless @buffer.eof?
          @offset = @buffer.tell
        end
      end
      
      def path
        @output.path if @output.respond_to? :path
      end
      
      def clear
        @mutex.synchronize do
          @buffer.rewind
          @offset = 0
        end
      end
      
      def close
        @buffer.close
        @output.close
      end
    
    end
    
    # Prints to a buffer. 
    # Must call flush to send to output. 
    class SyncLogger < Logger
      def print(level, *msg)
        return unless level <= @lev
        @mutex.synchronize { @buffer.print *msg }
      end

      def puts(level, *msg)
        #Stella.ld [level, @lev, msg]
        return unless level <= @lev
        @mutex.synchronize { @buffer.puts *msg }
      end
    end
    
    class Dumper
      FREQUENCY = Stella::Engine::LoadQueue::ROTATE_TIMELINE
      SLEEP = 2
      attr_accessor :force_stop
      attr_reader :dthread
      
      def stop()  
        @force_stop = true  
        @dthread.join
      end
      def stop?() @force_stop == true end
      
      # Execute yield every FREQUENCY seconds.
      def start(&blk)
        @dthread = Thread.new do
          prev_ptime = Time.now
          loop do
            break if Stella.abort? || stop?
            if (Time.now - prev_ptime).to_i >= FREQUENCY
              blk.call
              prev_ptime = Time.now
            end
            sleep SLEEP
          end

        end
      end
      
    end
  end
end