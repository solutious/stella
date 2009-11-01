

module Stella
  module Data
    
    module Logger
      @mutex = Mutex.new
      @output = StringIO.new
      @offset = 0
      @lev = 1
            
      class << self
        attr_accessor :lev
        
        def print(*msg)
          @mutex.synchronize do
            @output.print *msg
          end
        end

        def puts(*msg)
          @mutex.synchronize do
            @output.puts *msg
          end
        end

        def flush
          @mutex.synchronize do
            #return if @offset == @output.tell
            @output.seek @offset
            STDOUT.puts @output.read unless @output.eof?
            @offset = @output.tell
          end
        end
        
        def quiet?()        @lev == 0    end
        def enable_quiet()  @lev =  0    end
        def disable_quiet() @lev =  1    end
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