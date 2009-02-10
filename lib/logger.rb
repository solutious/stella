

module Stella
  class Logger
    attr_accessor :debug_level
    
    # +args+ is a hash of initialization arguments
    # * <tt>:info_logger</tt> The IO class for info level logging. Default: STDOUT
    # * <tt>:error_logger</tt> The IO class for error level logging. Default: STDERR
    # * <tt>:debug_logger</tt> The IO class for error level logging. Default: STDERR
    # * <tt>:debug_level</tt> An integer from 0 to 4 which determines the amount of debugging output. Default: 0.
    def initialize(args={})
      @debug_level        = args[:debug_level] || false
      @info_logger  = args[:info_logger]
      @error_logger = args[:error_logger]
      @debug_logger = args[:debug_logger]
    end
    
    # +msgs+ is an array which can contain a list of messages or a symbol and a list of values
    # If the first element is a symbol, this will return the output of Stella::Text.msg(msgs[0],msgs[1..-1]) 
    def info(*msgs)
      return if !msgs || msgs.empty?
      msgs.each do |m|
        info_logger.puts m
      end  
      info_logger.flush
    end
    
    def info_logger
      @info_logger || $stdout
    end
    def debug_logger
      @debug_logger || $stderr
    end
    def error_logger
      @error_logger || $stderr
    end
    
    def flush
      info_logger.flush
      error_logger.flush
      debug_logger.flush
    end
    
    # Print all messages on a single line. 
    def info_print(*msgs)
      msgs.each do |m|
        info_logger.print m
      end
      info_logger.flush
    end
    
    # Print all messages on a single line. 
    def info_printf(pattern, *vals)
      info_logger.printf(pattern, *vals)
      info_logger.flush
    end
    
    def debug(*msgs)
      return unless @debug_level
      msgs.each do |m|
        debug_logger.puts "DEBUG: #{m}"
      end  
      debug_logger.flush
    end
    def warn(ex, prefix="WARN: ")
      error(ex, prefix)
    end
    
    def error(ex, prefix="ERR: ")
      msg = (ex.kind_of? String) ? ex : ex.message
      error_logger.puts "#{prefix}#{msg}"
      return unless @debug_level > 0 && ex.kind_of?(Exception)
      error_logger.puts("#{prefix}------------------------------------------")
      error_logger.puts("#{prefix}#{ex.backtrace.join("\n")}")
      error_logger.puts("#{prefix}------------------------------------------")
    end
  end
end