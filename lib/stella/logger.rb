

module Stella

  class Logger
    @@disable = false
    def self.disable!()  @@disable = true  end
    def self.disabled?()  @@disable == true end
    
    attr_accessor :lev
    attr_reader :templates
    
    def initialize(output=STDOUT)
      @mutex, @buffer = Mutex.new, StringIO.new
      @lev, @offset = 1, 0
      @templates = {}
      @autoflush = false
      return if Logger.disabled?
      self.output = output
    end
    
    def autoflush!()  @autoflush = true   end
    def autoflush?()  @autoflush == true  end
      
    def add_template(name, str)
      @templates[name.to_sym] = str
    end
    
    def template(name)
      @templates[name]
    end
    
    def template?(name)
      @templates.has_key? name
    end
    
    def print(level, *msg)
      return if level > @lev || Logger.disabled?
      @buffer.print *msg
      flush if autoflush?
      true
    end
    def print!(level, msg)
      return unless @lev == level
      print level, msg
    end
    
    def puts(level, *msg)
      return if level > @lev || Logger.disabled?
      @buffer.puts *msg
      flush if autoflush?
      true
    end
    
    def info(*msg)   puts 1, *msg end
    def info1(*msg)  puts 1, *msg end
    def info2(*msg)  puts 2, *msg end
    def info3(*msg)  puts 3, *msg end
    def info4(*msg)  puts 4, *msg end
    
    def tinfo(templ, *args)
      info template(templ) % args
    end
    
    def twarn(templ, *args)
      warn template(templ) % args
    end
    
    class UnknownTemplate < Stella::Error
    end
    
    def method_missing(meth, *args)
      raise UnknownTemplate.new(meth.to_s) unless template? meth
      tinfo meth, *args
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
      return if Logger.disabled?
      @mutex.synchronize do
        #return if @offset == @output.tell
        @buffer.seek @offset
        @output.print @buffer.read unless @buffer.eof?
        @offset = @buffer.tell
        @output.flush
      end
      true
    end
    
    def path
      @output.path if @output.respond_to? :path
    end
    
    def clear
      return if Logger.disabled?
      flush
      @mutex.synchronize do
        @buffer.rewind
        @offset = 0
      end
    end
    
    def close
      return if Logger.disabled?
      flush
      @buffer.close
      @output.close
    end
  
  end
  
  # Prints to a buffer. 
  # Must call flush to send to output. 
  class SyncLogger < Logger
    def print(level, *msg)
      return if level > @lev || Logger.disabled?
      @mutex.synchronize { 
        @buffer.print *msg 
        flush if autoflush?
      }
      true
    end

    def puts(level, *msg)
      #Stella.ld [level, @lev, msg]
      return if level > @lev || Logger.disabled?
      @mutex.synchronize { 
        @buffer.puts *msg 
        flush if autoflush?
      }
      true
    end
  end

end