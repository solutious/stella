require 'optparse'
require 'ostruct'
require 'pp'


module Drydock
  class Command
    attr_reader :cmd, :index
    def initialize(cmd, index, &b)
      @cmd = (cmd.kind_of?(Symbol)) ? cmd.to_s : cmd
      @index = index
      @b = b
    end
    
    def call(cmd_str, argv, stdin, global_options, options)
      block_args = [options, argv, global_options, stdin, cmd_str, self]
      @b.call(*block_args[0..(@b.arity-1)])
    end
    def to_s
      @cmd.to_s
    end
  end
end

module Drydock
  class UnknownCommand < RuntimeError
    attr_reader :name
    def initialize(name)
      @name = name || :unknown
    end
  end
  class NoCommandsDefined < RuntimeError
  end
  class InvalidArgument < RuntimeError
    attr_accessor :args
    def initialize(args)
      # We grab just the name of the argument
      @args = args || []
    end
  end
  class MissingArgument < InvalidArgument
  end
end

# Drydock is a DSL for command-line apps. 
# See bin/example for usage examples. 
module Drydock
  extend self
  
  FORWARDED_METHODS = %w(command before alias_command global_option global_usage usage option stdin default commands).freeze
 
  def default(cmd)
    @default_command = canonize(cmd)
  end
  
  def stdin(&b)
    @stdin_block = b
  end
  def before(&b)
    @before_block = b
  end
  
  
  # ex: usage "Usage: frylla [global options] command [command options]"
  def global_usage(msg)
    @global_opts_parser ||= OptionParser.new 
    @global_options ||= OpenStruct.new
  
    @global_opts_parser.banner = msg
  end
  

  
  # Split the +argv+ array into global args and command args and 
  # find the command name. 
  # i.e. ./script -H push -f (-H is a global arg, push is the command, -f is a command arg)
  # returns [global_options, cmd, command_options, argv]
  def process_arguments(argv)
    global_options = command_options = {}
    cmd = nil     
    
    global_parser = @global_opts_parser
    
    global_options = global_parser.getopts(argv)
    global_options = global_options.keys.inject({}) do |hash, key|
       hash[key.to_sym] = global_options[key]
       hash
    end
    
    cmd_name = (argv.empty?) ? @default_command : argv.shift
    raise UnknownCommand.new(cmd_name) unless command?(cmd_name)
    
    cmd = get_command(cmd_name) 
    command_parser = @command_opts_parser[cmd.index]
    
    command_options = command_parser.getopts(argv) if (!argv.empty? && command_parser)
    command_options = command_options.keys.inject({}) do |hash, key|
       hash[key.to_sym] = command_options[key]
       hash
    end
    
    [global_options, cmd_name, command_options, argv]
  end
  

  
  def usage(msg)
    get_current_option_parser.banner = msg
  end
  

  # Grab the options parser for the current command or create it if it doesn't exist.
  def get_current_option_parser
    @command_opts_parser ||= []
    @command_index ||= 0
    (@command_opts_parser[@command_index] ||= OptionParser.new)
  end
  
  def global_option(*args, &b)
    @global_opts_parser ||= OptionParser.new
    args.unshift(@global_opts_parser)
    option_parser(args, &b)
  end
  
  def option(*args, &b)
    args.unshift(get_current_option_parser)
    option_parser(args, &b)
  end
  
  # Processes calls to option and global_option. Symbols are converted into 
  # OptionParser style strings (:h and :help become '-h' and '--help'). If a 
  # class is included, it will tell OptionParser to expect a value otherwise
  # it assumes a boolean value.
  #
  # +args+ is passed directly to OptionParser.on so it can contain anything
  # that's valid to that method. Some examples:
  # [:h, :help, "Displays this message"]
  # [:m, :max, Integer, "Maximum threshold"]
  # ['-l x,y,z', '--lang=x,y,z', Array, "Requested languages"]
  def option_parser(args=[], &b)
    return if args.empty?
    opts_parser = args.shift
    
    symbol_switches = []
    args.each_with_index do |arg, index|
      if arg.is_a? Symbol
        args[index] = (arg.to_s.length == 1) ? "-#{arg.to_s}" : "--#{arg.to_s}"
        symbol_switches << args[index]
      elsif arg.kind_of?(Class)
        symbol_switches.each do |arg|
          arg << "=S"
        end
      end
    end
    
    if args.size == 1
      opts_parser.on(args.shift)
    else
      opts_parser.on(*args) do |v|
        block_args = [v, opts_parser]
        result = (b.nil?) ? v : b.call(*block_args[0..(b.arity-1)])
      end
    end
  end
  
  def command(*cmds, &b)
    @command_index ||= 0
    @command_opts_parser ||= []
    cmds.each do |cmd| 
      c = Command.new(cmd, @command_index, &b)
      (@commands ||= {})[cmd] = c
    end
    
    @command_index += 1
  end
  
  def alias_command(aliaz, cmd)
    return unless @commands.has_key? cmd
    @commands[aliaz] = @commands[cmd]
  end
  
  def run?
    @@has_run ||= false
  end
  
  # Execute the given command.
  # By default, Drydock automatically executes itself and provides handlers for known errors.
  # You can override this functionality by calling +Drydock.run!+ yourself. Drydock
  # will only call +run!+ once. 
  def run!(argv, stdin=nil)
    return if run?
    @@has_run = true
    raise NoCommandsDefined.new unless @commands
    @global_options, cmd_name, @command_options, argv = process_arguments(argv)
    
    cmd_name ||= @default_command
    
    raise UnknownCommand.new(cmd_name) unless command?(cmd_name)
    
    stdin = (defined? @stdin_block) ? @stdin_block.call(stdin, []) : stdin
    @before_block.call if defined? @before_block
    
    call_command(cmd_name, argv, stdin)
    
  rescue OptionParser::InvalidOption => ex
    raise Drydock::InvalidArgument.new(ex.args)
  rescue OptionParser::MissingArgument => ex
    raise Drydock::MissingArgument.new(ex.args)
  end
  
  
  def call_command(cmd_str, argv=[], stdin=nil)
    return unless command?(cmd_str)
    get_command(cmd_str).call(cmd_str, argv, stdin, @global_options, @command_options)
  end
  
  def get_command(cmd)
    return unless command?(cmd)
    @commands[canonize(cmd)]
  end 
  
  def commands
    @commands
  end
  
  def command?(cmd)
    name = canonize(cmd)
    (@commands || {}).has_key? name
  end
  def canonize(cmd)
    return unless cmd
    return cmd if cmd.kind_of?(Symbol)
    cmd.tr('-', '_').to_sym
  end
  
end


Drydock::FORWARDED_METHODS.each do |m|
  eval(<<-end_eval, binding, "(Drydock)", __LINE__)
    def #{m}(*args, &b)
      Drydock.#{m}(*args, &b)
    end
  end_eval
end


at_exit {
  begin
    Drydock.run!(ARGV, STDIN)
  
  rescue Drydock::UnknownCommand => ex
    STDERR.puts "Frylock: I don't know what the #{ex.name} command is. #{$/}"
    STDERR.puts "Master Shake: I'll tell you what it is, friends... it's shut up and let me eat it."
  
  rescue Drydock::NoCommandsDefined => ex
    STDERR.puts "Frylock: Carl, I don't want it. And I'd appreciate it if you'd define at least one command. #{$/}"
    STDERR.puts "Carl: Fryman, don't be that way! This sorta thing happens every day! People just don't... you know, talk about it this loud."

  rescue Drydock::InvalidArgument => ex
    STDERR.puts "Frylock: Shake, how many arguments have you not provided a value for this year? #{$/}"
    STDERR.puts "Master Shake: A *lot* more than *you* have! (#{ex.args.join(', ')})"

  rescue Drydock::MissingArgument => ex
    STDERR.puts "Frylock: I don't know what #{ex.args.join(', ')} is. #{$/}"
    STDERR.puts "Master Shake: I'll tell you what it is, friends... it's shut up and let me eat it."

  rescue => ex
    STDERR.puts "Master Shake: Okay, but when we go in, watch your step. "
    STDERR.puts "Frylock: Why?"
    STDERR.puts "Meatwad: [explosion] #{ex.message}"
    STDERR.puts ex.backtrace
  end
}

  
