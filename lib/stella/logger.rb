

module Stella
  class Logger
    attr_accessor :debug
    
    # +args+ is a hash of initialization arguments
    # * <tt>:info_logger</tt> The IO class for info level logging. Default: STDOUT
    # * <tt>:error_logger</tt> The IO class for error level logging. Default: STDERR
    # * <tt>:debug_logger</tt> The IO class for error level logging. Default: STDERR
    # * <tt>:debug</tt> Log debugging output, true or false (default)
    def initialize(args={})
      @debug        = args[:debug] || false
      @info_logger  = args[:info_logger] || STDOUT
      @error_logger = args[:error_logger] || STDERR
      @debug_logger = args[:debug_logger] || STDERR
    end
    
    # +msgs+ is an array which can contain a list of messages or a symbol and a list of values
    # If the first element is a symbol, this will return the output of Stella::Text.msg(msgs[0],msgs[1..-1]) 
    def info(*msgs)
      return if !msgs || msgs.empty?
      if msgs[0].is_a? Symbol
        txtsym = msgs.shift
        @info_logger.puts Stella::TEXT.msg(txtsym, msgs)
      else
        msgs.each do |m|
          @info_logger.puts m
        end  
      end
      @info_logger.flush
    end
    
    # Print all messages on a single line. 
    def info_print(*msgs)
      msgs.each do |m|
        @info_logger.print m
      end
      @info_logger.flush
    end
    
    # Print all messages on a single line. 
    def info_printf(pattern, *vals)
      @info_logger.printf(pattern, *vals)
      @info_logger.flush
    end
    
    def debug(*msgs)
      return unless @debug
      msgs.each do |m|
        @debug_logger.puts "DEBUG: #{m}"
      end  
      @debug_logger.flush
    end
    def error(ex, prefix="ERR: ")
      @error_logger.puts "#{prefix}#{ex.message}"
      return unless @debug
      @error_logger.puts("#{prefix}------------------------------------------")
      @error_logger.puts("#{prefix}#{ex.backtrace.join("\n")}")
      @error_logger.puts("#{prefix}------------------------------------------")
    end
  end
end