require 'stringio'
require 'irb/ruby-lex'
#SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

class ProcString < String
  attr_accessor :file, :lines, :arity, :kind
  def to_proc
    result = eval("proc #{self}")
    result.source = self
    result
  end
  def to_lambda
    result = eval("lambda #{self}")
    result.source = self
    result
  end
end

# Based heavily on code from http://github.com/imedo/background
# Big thanks to the imedo dev team!
#
module ProcSource
  
  def self.find(filename, start_line=0, block_only=true)
    lines, lexer = nil, nil
    retried = 0
    loop do
      lines = get_lines(filename, start_line)
      if !line_has_open?(lines.join) && start_line >= 0
        start_line -= 1 and retried +=1 and redo 
      end
      lexer = RubyLex.new
      lexer.set_input(StringIO.new(lines.join))
      break
    end
    stoken, etoken, nesting = nil, nil, 0
    while token = lexer.token
      n = token.instance_variable_get(:@name)
#        p [:parser, nesting, token.class, n]
      if RubyToken::TkIDENTIFIER === token
        #p n
      elsif RubyToken::TkDO === token ||
            RubyToken::TkfLBRACE === token 
        nesting += 1
        stoken = token if nesting == 1
      elsif RubyToken::TkBITOR === token && stoken
        
      elsif RubyToken::TkEND === token ||
            RubyToken::TkRBRACE === token
        if nesting == 1
          etoken = token 
          break
        end
        nesting -= 1
      elsif RubyToken::TkNL === token && stoken && etoken
        break if nesting <= 0
      else
        #p token
      end
    end
    #puts lines if etoken.nil?
    lines = lines[stoken.line_no-1 .. etoken.line_no-1]
    
    # Remove the crud before the block definition. 
    if block_only
      spaces = lines.last.match(/^\s+/)[0] rescue ''
      lines[0] = spaces << lines[0][stoken.char_no .. -1]
    end
    ps = ProcString.new lines.join
    ps.file, ps.lines = filename, start_line .. start_line+etoken.line_no-1
    
    ps
  end
  
  # A hack for Ruby 1.9, otherwise returns true.
  #
  # Ruby 1.9 returns an incorrect line number
  # when a block is specified with do/end. It
  # happens b/c the line number returned by 
  # Ruby 1.9 is based on the first line in the
  # block which contains a token (i.e. not a
  # new line or comment etc...). 
  #
  # NOTE: This won't work in cases where the 
  # incorrect line also contains a "do". 
  #
  def self.line_has_open?(str)
    return true unless RUBY_VERSION >= '1.9'
    lexer = RubyLex.new
    lexer.set_input(StringIO.new(str))
    success = false
    while token = lexer.token
      case token
      when RubyToken::TkNL
        break
      when RubyToken::TkDO
        success = true
      end
    end
    success
  end
  
  
  def self.get_lines(filename, start_line = 0)
    case filename
      when nil
        nil
      ## NOTE: IRB AND EVAL LINES NOT TESTED
      ### special "(irb)" descriptor?
      ##when "(irb)"
      ##  IRB.conf[:MAIN_CONTEXT].io.line(start_line .. -2)
      ### special "(eval...)" descriptor?
      ##when /^\(eval.+\)$/
      ##  EVAL_LINES__[filename][start_line .. -2]
      # regular file
      else
        # Ruby already parsed this file? (see disclaimer above)
        if defined?(SCRIPT_LINES__) && SCRIPT_LINES__[filename]
          SCRIPT_LINES__[filename][(start_line - 1) .. -1]
        # If the file exists we're going to try reading it in
        elsif File.exist?(filename)
          begin
            File.readlines(filename)[(start_line - 1) .. -1]
          rescue
            nil
          end
        end
    end
  end
end

class Proc #:nodoc:
  attr_reader :file, :line
  attr_writer :source
  
  def source_descriptor
    unless @file && @line
      if md = /^#<Proc:0x[0-9A-Fa-f]+@(.+):(\d+)(.+?)?>$/.match(inspect)
        @file, @line = md.captures
      end
    end
    [@file, @line.to_i]
  end
  
  def source
    @source ||= ProcSource.find(*self.source_descriptor)
  end
  

end

if $0 == __FILE__
  def store(&blk)
    @blk = blk
  end

  store do |a|
    puts "Hello Rudy"
  end

  a = Proc.new() { |a|
    puts { "Hello Rudy" }
}

b = Proc.new() do |a|
    puts {"Hello Rudy"}
  end
  
  puts a.source
  puts b.source
  puts @blk.source
  
  proc = @blk.source.to_proc
  proc.call
end


__END__

# THE FOLLOWING WAS TAKEN FROM
# http://github.com/imedo/background
# AND IS THE BASIS OF THE CODE ABOVE. 
#

require 'stringio'
require 'irb/ruby-lex'
 
# Tell the ruby interpreter to load code lines of required files
# into this filename -> lines Hash. This behaviour seems to be
# very undocumented and therefore shouldn't really be relied on.
SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__
 
module ProcSource #:nodoc:
  def get_lines(filename, start_line = 0)
    case filename
      when nil
        nil
      # special "(irb)" descriptor?
      when "(irb)"
        IRB.conf[:MAIN_CONTEXT].io.line(start_line .. -1)
      # special "(eval...)" descriptor?
      when /^\(eval.+\)$/
        EVAL_LINES__[filename][start_line .. -1]
      # regular file
      else
        # Ruby already parsed this file? (see disclaimer above)
        if lines = SCRIPT_LINES__[filename]
          lines[(start_line - 1) .. -1]
        # If the file exists we're going to try reading it in
        elsif File.exist?(filename)
          begin
            File.readlines(filename)[(start_line - 1) .. -1]
          rescue
            nil
          end
        end
    end
  end
 
  def handle(proc)
    filename, line = proc.source_descriptor
    lines = get_lines(filename, line) || []
 
    lexer = RubyLex.new
    lexer.set_input(StringIO.new(lines.join))
 
    state = :before_constructor
    nesting_level = 1
    start_token, end_token = nil, nil
    found = false
    while token = lexer.token
      p token
      # we've not yet found any proc-constructor -- we'll try to find one.
      if [:before_constructor, :check_more].include?(state)
        # checking more and newline? -> done
        if token.is_a?(RubyToken::TkNL) and state == :check_more
          state = :done
          break
        end
        # token is Proc?
        if token.is_a?(RubyToken::TkCONSTANT) and
           token.instance_variable_get(:@name) == "Proc"
          # method call?
          if lexer.token.is_a?(RubyToken::TkDOT)
            method = lexer.token
            # constructor?
            if method.is_a?(RubyToken::TkIDENTIFIER) and
               method.instance_variable_get(:@name) == "new"
              unless state == :check_more
                # okay, code will follow soon.
                state = :before_code
              else
                # multiple procs on one line
                return
              end
            end
          end
        # token is lambda or proc call?
        elsif token.is_a?(RubyToken::TkIDENTIFIER) and
              %w{proc lambda}.include?(token.instance_variable_get(:@name))
          unless state == :check_more
            # okay, code will follow soon.
            state = :before_code
          else
            # multiple procs on one line
            return
          end
        elsif token.is_a?(RubyToken::TkfLBRACE) or token.is_a?(RubyToken::TkDO)
          # found the code start, update state and remember current token
          state = :in_code
          start_token = token
        end
 
      # we're waiting for the code start to appear.
      elsif state == :before_code
        
        if token.is_a?(RubyToken::TkfLBRACE) or token.is_a?(RubyToken::TkDO)
          # found the code start, update state and remember current token
          state = :in_code
          start_token = token
        end
 
      # okay, we're inside code
      elsif state == :in_code
        if token.is_a?(RubyToken::TkRBRACE) or token.is_a?(RubyToken::TkEND)
          nesting_level -= 1
          if nesting_level == 0
            # we're done!
            end_token = token
            # parse another time to check if there are multiple procs on one line
            # we can't handle that case correctly so we return no source code at all
            state = :check_more
          end
        elsif token.is_a?(RubyToken::TkfLBRACE) or token.is_a?(RubyToken::TkDO) or
              token.is_a?(RubyToken::TkBEGIN) or token.is_a?(RubyToken::TkCASE) or
              token.is_a?(RubyToken::TkCLASS) or token.is_a?(RubyToken::TkDEF) or
              token.is_a?(RubyToken::TkFOR) or token.is_a?(RubyToken::TkIF) or
              token.is_a?(RubyToken::TkMODULE) or token.is_a?(RubyToken::TkUNLESS) or
              token.is_a?(RubyToken::TkUNTIL) or token.is_a?(RubyToken::TkWHILE) or
              token.is_a?(RubyToken::TklBEGIN)
          nesting_level += 1
        end
      end
    end
 
    if start_token and end_token
      start_line, end_line = start_token.line_no - 1, end_token.line_no - 1
      source = lines[start_line .. end_line]
      start_offset = start_token.char_no
      start_offset += 1 if start_token.is_a?(RubyToken::TkDO)
      end_offset = -(source.last.length - end_token.char_no)
      source.first.slice!(0 .. start_offset)
      source.last.slice!(end_offset .. -1)
 
      # Can't use .strip because newline at end of code might be important
      # (Stuff would break when somebody does proc { ... #foo\n})
      proc.source = source.join.gsub(/^ | $/, "")
    end
  end
 
  module_function :handle, :get_lines
end
 
class Proc #:nodoc:
  attr_reader :file, :line
  
  def source_descriptor
    return @file, @line.to_i if @file && @line
    md = /^#<Proc:0x[0-9A-Fa-f]+@(.+):(\d+)(.+?)?>$/.match(old_inspect)
    if md 
      @file, @line = md.captures
      return @file, @line.to_i
    end
  end
  
  def self.source_cache
    @source_cache ||= {}
  end
 
  def source=(code)
    @source = Proc.source_cache[source_descriptor.join('/')] = code
  end
 
  def source
    @source = Proc.source_cache[source_descriptor.join('/')]
    ProcSource.handle(self) #unless @source
    @source
  end
 
  alias :old_inspect :inspect
  def inspect
    if source
      "proc {#{source}}"
    else
      old_inspect
    end
  end
 
  def ==(other)
    if self.source && other.respond_to?(:source) && other.source
      self.source == other.source
    else
      self.object_id == other.object_id
    end
  end
 
  def _dump(depth = 0)
    if source
      source
    else
      raise(TypeError, "Can't serialize Proc with unknown source code.")
    end
  end
 
  def to_yaml(*args)
    #self.source # force @source to be set
    a = super
    a.sub!("object:Proc", "proc") if a.respond_to? :sub
    a
  end
 
  def self.allocate; from_string ""; end
 
  def self.from_string(string)
    result = eval("proc {#{string}}")
    result.source = string
    return result
  end
 
  def self._load(code)
    self.from_string(code)
  end
 
  def self.marshal_load; end
  def marshal_load; end
end
 
require 'yaml'
YAML.add_ruby_type(/^proc/) do |type, val|
  Proc.from_string(val["source"])
end
 
# EVAL_LINES__ = Hash.new
#
# alias :old_eval :eval
# def eval(code, *args)
# context, descriptor, start_line, *more = *args
# descriptor ||= "(eval#{code.hash})"
# start_line ||= 0
# lines ||= code.grep(/.*/)
# EVAL_LINES__[descriptor] ||= Array.new
# EVAL_LINES__[descriptor][start_line, lines.length] = lines
# old_eval(code, context, descriptor, start_line, *more)
# end
 

if __FILE__ == $0 then
  require "pstore"
 
  code = Proc.new() {
     puts "Hello World!"
   }

  
  File.open("proc.marshalled", "w") { |file| Marshal.dump(code, file) }
  code = File.open("proc.marshalled") { |file| Marshal.load(file) }
 
  code.call
 
  store = PStore.new("proc.pstore")
  store.transaction do
    store["proc"] = code
  end
  store.transaction do
    code = store["proc"]
  end
  
  code.call
  
  File.open("proc.yaml", "w") { |file| YAML.dump(code) }
  #code = File.open("proc.yaml") { |file| YAML.load(file) }
  
  code.call
end