#encoding: utf-8
#
# STELLA INLINE DEPENDENCIES
#
# Ruby require is painfully slow which is okay for
# long running processes like web applications but
# blows major goats for command-line apps. 
#
# This file combines several dependencies into one.
#

#################################################
# MIXINS
#################################################

$KCODE = "u" if RUBY_VERSION =~ /^1.8/


# Assumes Time::Units and Numeric mixins are available. 

class String
  def in_seconds
    # "60m" => ["60", "m"]
    q,u = self.scan(/([\d\.]+)([s,m,h])?/).flatten
    q &&= q.to_f and u ||= 's'
    q &&= q.in_seconds(u)
  end
end

class Symbol
  def downcase
    self.to_s.downcase.to_sym
  end
  def upcase
    self.to_s.upcase.to_sym
  end
end


# Fix for eventmachine in Ruby 1.9
class Thread
  unless method_defined? :kill!
    def kill!(*args) kill( *args) end
  end
end


class Time
  module Units
    PER_MICROSECOND = 0.000001.freeze
    PER_MILLISECOND = 0.001.freeze
    PER_MINUTE = 60.0.freeze
    PER_HOUR = 3600.0.freeze
    PER_DAY = 86400.0.freeze
    
    def microseconds()    seconds * PER_MICROSECOND     end
    def milliseconds()    seconds * PER_MILLISECOND    end
    def seconds()         self                         end
    def minutes()         seconds * PER_MINUTE          end
    def hours()           seconds * PER_HOUR             end
    def days()            seconds * PER_DAY               end
    def weeks()           seconds * PER_DAY * 7           end
    def years()           seconds * PER_DAY * 365        end 
            
    def in_years()        seconds / PER_DAY / 365      end
    def in_weeks()        seconds / PER_DAY / 7       end
    def in_days()         seconds / PER_DAY          end
    def in_hours()        seconds / PER_HOUR          end
    def in_minutes()      seconds / PER_MINUTE         end
    def in_milliseconds() seconds / PER_MILLISECOND    end
    def in_microseconds() seconds / PER_MICROSECOND   end

    def in_seconds(u=nil)
      case u.to_s
      when /\A(y)|(years?)\z/
        years
      when /\A(w)|(weeks?)\z/
        weeks
      when /\A(d)|(days?)\z/
        days
      when /\A(h)|(hours?)\z/
        hours
      when /\A(m)|(minutes?)\z/
        minutes
      when /\A(ms)|(milliseconds?)\z/
        milliseconds
      when /\A(us)|(microseconds?)|(μs)\z/
        microseconds
      else
        self
      end
    end
    
    ## JRuby doesn't like using instance_methods.select here. 
    ## It could be a bug or something quirky with Attic 
    ## (although it works in 1.8 and 1.9). The error:
    ##  
    ##  lib/attic.rb:32:in `select': yield called out of block (LocalJumpError)
    ##  lib/stella/mixins/numeric.rb:24
    ##
    ## Create singular methods, like hour and day. 
    # instance_methods.select.each do |plural|
    #   singular = plural.to_s.chop
    #   alias_method singular, plural
    # end
    
    alias_method :ms, :milliseconds
    alias_method :'μs', :microseconds
    alias_method :second, :seconds
    alias_method :minute, :minutes
    alias_method :hour, :hours
    alias_method :day, :days
    alias_method :week, :weeks
    alias_method :year, :years

  end
end

class Numeric
  include Time::Units
  # TODO: Use 1024?
  def to_bytes
    args = case self.abs.to_i
    when 0..1000
      [(self).to_s, 'B']
    when (1000)..(1000**2)
      [(self / 1000.to_f).to_s, 'KB']
    when (1000**2)..(1000**3)
      [(self / (1000**2).to_f).to_s, 'MB']
    when (1000**3)..(1000**4)
      [(self / (1000**3).to_f).to_s, 'GB']
    when (1000**4)..(1000**6)
      [(self / (1000**4).to_f).to_s, 'TB']
    else
      [self, 'B']
    end
    '%3.2f%s' % args
  end
end

class Hash
  
  # Courtesy of Julien Genestoux
  def flatten
    params = {}
    stack = []

    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      elsif v.is_a?(Array)
        stack << [k,Hash.from_array(v)]
      else
        params[k] =  v
      end
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params["#{parent}[#{k}]"] = v
        end
      end
    end

    params
  end
  
  # Courtesy of Julien Genestoux
  # See: http://stackoverflow.com/questions/798710/how-to-turn-a-ruby-hash-into-http-params
  def to_params
    params = ''
    stack = []

    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      elsif v.is_a?(Array)
        stack << [k,Hash.from_array(v)]
      else
        params << "#{k}=#{v}&"
      end
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end

    params.chop! 
    params
  end
  def self.from_array(array = [])
    h = Hash.new
    array.size.times do |t|
      h[t] = array[t]
    end
    h
  end

end


#################################################
# GEM: STORABLE 0.6.3
#################################################

#--
# TODO: Handle nested hashes and arrays.
# TODO: to_xml, see: http://codeforpeople.com/lib/ruby/xx/xx-2.0.0/README
#++


# AUTHOR
#    jan molic /mig/at/1984/dot/cz/
#
# DESCRIPTION
#    Hash with preserved order and some array-like extensions
#    Public domain. 
#
# THANKS
#    Andrew Johnson for his suggestions and fixes of Hash[],
#    merge, to_a, inspect and shift
class Storable
  class OrderedHash < ::Hash
    attr_accessor :order

    class << self
        def [] *args
          hsh = Storable::OrderedHash.new
          if Hash === args[0]
            hsh.replace args[0]
          elsif (args.size % 2) != 0
            raise ArgumentError, "odd number of elements for Hash"
          else
            0.step(args.size - 1, 2) do |a|
              b = a + 1
              hsh[args[a]] = args[b]
            end
          end
          hsh
        end
    end
    def initialize(*a, &b)
      super
      @order = []
    end
    def store_only a,b
        store a,b
    end
    alias orig_store store    
    def store a,b
        @order.push a unless has_key? a
        super a,b
    end
    alias []= store
    def == hsh2
        return false if @order != hsh2.order
        super hsh2
    end
    def clear
        @order = []
        super
    end
    def delete key
        @order.delete key
        super
    end
    def each_key
        @order.each { |k| yield k }
        self
    end
    def each_value
        @order.each { |k| yield self[k] }
        self
    end
    def each
        @order.each { |k| yield k,self[k] }
        self
    end
    alias each_pair each    
    def delete_if
        @order.clone.each { |k| 
            delete k if yield(k)
        }
        self
    end
    def values
        ary = []
        @order.each { |k| ary.push self[k] }
        ary
    end
    def keys
        @order
    end
    def first
      {@order.first => self[@order.first]}
    end
    def last
      {@order.last => self[@order.last]}
    end
    def invert
        hsh2 = Hash.new    
        @order.each { |k| hsh2[self[k]] = k }
        hsh2
    end
    def reject &block
        self.dup.delete_if( &block)
    end
    def reject! &block
        hsh2 = reject( &block)
        self == hsh2 ? nil : hsh2
    end
    def replace hsh2
        @order = hsh2.keys 
        super hsh2
    end
    def shift
        key = @order.first
        key ? [key,delete(key)] : super
    end
    def unshift k,v
        unless self.include? k
            @order.unshift k
            orig_store(k,v)
            true
        else
            false
        end
    end
    def push k,v
        unless self.include? k
            @order.push k
            orig_store(k,v)
            true
        else
            false
        end
    end
    def pop
        key = @order.last
        key ? [key,delete(key)] : nil
    end
    def to_a
        ary = []
        each { |k,v| ary << [k,v] }
        ary
    end
    def to_s
        self.to_a.to_s
    end
    def inspect
        ary = []
        each {|k,v| ary << k.inspect + "=>" + v.inspect}
        '{' + ary.join(", ") + '}'
    end
    def update hsh2
        hsh2.each { |k,v| self[k] = v }
        self
    end
    alias :merge! update
    def merge hsh2
        ##self.dup update(hsh2)   ## 2009-05-12 -- delano
        update hsh2               ## dup doesn't take an argument
                                  ## and there's no need for it here
    end
    def select
        ary = []
        each { |k,v| ary << [k,v] if yield k,v }
        ary
    end
    def class
      Hash
    end
    def __class__
      Storable::OrderedHash
    end

    attr_accessor "to_yaml_style"
    def yaml_inline= bool
      if respond_to?("to_yaml_style")
        self.to_yaml_style = :inline
      else
        unless defined? @__yaml_inline_meth
          @__yaml_inline_meth =
            lambda {|opts|
              YAML::quick_emit(object_id, opts) {|emitter|
                emitter << '{ ' << map{|kv| kv.join ': '}.join(', ') << ' }'
              }
            }
          class << self
            def to_yaml opts = {}
              begin
                @__yaml_inline ? @__yaml_inline_meth[ opts ] : super
              rescue
                @to_yaml_style = :inline
                super
              end
            end
          end
        end
      end
      @__yaml_inline = bool
    end
    def yaml_inline!() self.yaml_inline = true end

    def each_with_index
      @order.each_with_index { |k, index| yield k, self[k], index }
      self
    end
  end
end # class Storable::OrderedHash



USE_ORDERED_HASH = (RUBY_VERSION =~ /^1.9/).nil?

begin
  require 'json'
rescue LoadError
  # Silently!
end
  
require 'yaml'
require 'fileutils'
require 'time'


class Storable
  module DefaultProcessors
    def hash_proc_processor 
      Proc.new do |procs|
        a = {}
        procs.each_pair { |n,v| 
          a[n] = (Proc === v) ? v.source : v 
        }
        a
      end
    end
  end
end

# Storable makes data available in multiple formats and can
# re-create objects from files. Fields are defined using the 
# Storable.field method which tells Storable the order and 
# name.
class Storable
  extend Storable::DefaultProcessors
  
  unless defined?(SUPPORTED_FORMATS) # We can assume all are defined
    VERSION = "0.6.3"
    NICE_TIME_FORMAT  = "%Y-%m-%d@%H:%M:%S".freeze 
    SUPPORTED_FORMATS = [:tsv, :csv, :yaml, :json, :s, :string].freeze 
  end
  
  class << self
    attr_accessor :field_names, :field_types
  end
  
  # This value will be used as a default unless provided on-the-fly.
  # See SUPPORTED_FORMATS for available values.
  attr_reader :format
  
  # See SUPPORTED_FORMATS for available values
  def format=(v)
    v &&= v.to_sym
    raise "Unsupported format: #{v}" unless SUPPORTED_FORMATS.member?(v)
    @format = v
  end
  
  def postprocess
  end
  
  # TODO: from_args([HASH or ordered params])
  
  # Accepts field definitions in the one of the follow formats:
  #
  #     field :product
  #     field :product => Integer
  #     field :product do |val|
  #       # modify val before it's stored. 
  #     end
  #
  # The order they're defined determines the order the will be output. The fields
  # data is available by the standard accessors, class.product and class.product= etc...
  # The value of the field will be cast to the type (if provided) when read from a file. 
  # The value is not touched when the type is not provided. 
  def self.field(args={}, &processor)
    # TODO: Examine casting from: http://codeforpeople.com/lib/ruby/fattr/fattr-1.0.3/
    args = {args => nil} unless args.kind_of?(Hash)

    args.each_pair do |m,t|
      self.field_names ||= []
      self.field_types ||= []
      self.field_names << m
      self.field_types << t unless t.nil?
      
      unless processor.nil?
        define_method("_storable_processor_#{m}", &processor)
      end
      
      next if method_defined?(m) # don't refine the accessor methods
      
      define_method(m) do instance_variable_get("@#{m}") end
      define_method("#{m}=") do |val| 
        instance_variable_set("@#{m}",val)
      end
    end
  end
  
  def self.has_field?(n)
    field_names.member? n.to_sym
  end
  def has_field?(n)
    self.class.field_names.member? n.to_sym
  end
  
  # +args+ is a list of values to set amongst the fields. 
  # It's assumed that the order values matches the order
  def initialize(*args)
    (self.class.field_names || []).each_with_index do |n,index|
      break if (index+1) >= args.size
      self.send("#{n}=", args[index])
    end
  end

  # Returns an array of field names defined by self.field
  def field_names
    self.class.field_names
  end
  # Returns an array of field types defined by self.field. Fields that did 
  # not receive a type are set to nil.
  def field_types
    self.class.field_types
  end

  # Dump the object data to the given format. 
  def dump(format=nil, with_titles=false)
    format &&= format.to_sym
    format ||= 's' # as in, to_s
    raise "Format not defined (#{format})" unless SUPPORTED_FORMATS.member?(format)
    send("to_#{format}") 
  end
  
  def to_string(*args)
    to_s(*args)
  end
  
  # Create a new instance of the object using data from file. 
  def self.from_file(file_path, format='yaml')
    raise "Cannot read file (#{file_path})" unless File.exists?(file_path)
    raise "#{self} doesn't support from_#{format}" unless self.respond_to?("from_#{format}")
    format = format || File.extname(file_path).tr('.', '')
    me = send("from_#{format}", read_file_to_array(file_path))
    me.format = format
    me
  end
  # Write the object data to the given file. 
  def to_file(file_path=nil, with_titles=true)
    raise "Cannot store to nil path" if file_path.nil?
    format = File.extname(file_path).tr('.', '')
    format &&= format.to_sym
    format ||= @format
    Storable.write_file(file_path, dump(format, with_titles))
  end

  # Create a new instance of the object from a hash.
  def self.from_hash(from={})
    return nil if !from || from.empty?
    me = self.new
    me.from_hash(from)
  end
  
  def from_hash(from={})
    fnames = field_names
    fnames.each_with_index do |key,index|
      
      stored_value = from[key] || from[key.to_s] # support for symbol keys and string keys
      
      # TODO: Correct this horrible implementation 
      # (sorry, me. It's just one of those days.) -- circa 2008-09-15
      
      if field_types[index] == Array
        ((value ||= []) << stored_value).flatten 
      elsif field_types[index].kind_of?(Hash)
        
        value = stored_value
      else
        
        # SimpleDB stores attribute shit as lists of values
        ##value = stored_value.first if stored_value.is_a?(Array) && stored_value.size == 1
        value = (stored_value.is_a?(Array) && stored_value.size == 1) ? stored_value.first : stored_value
        
        if field_types[index] == Time
          value = Time.parse(value)
        elsif field_types[index] == DateTime
          value = DateTime.parse(value)
        elsif field_types[index] == TrueClass
          value = (value.to_s == "true")
        elsif field_types[index] == Float
          value = value.to_f
        elsif field_types[index] == Integer
          value = value.to_i
        elsif field_types[index].kind_of?(Storable) && stored_value.kind_of?(Hash)
          # I don't know why this is here so I'm going to raise an exception
          # and wait a while for an error in one of my other projects. 
          #value = field_types[index].from_hash(stored_value)
          raise "Delano, delano, delano. Clean up Storable!"
        end
      end
      
      self.send("#{key}=", value) if self.respond_to?("#{key}=")  
    end

    self.postprocess
    self
  end
  # Return the object data as a hash
  # +with_titles+ is ignored. 
  def to_hash
    tmp = USE_ORDERED_HASH ? Storable::OrderedHash.new : {}
    field_names.each do |fname|
      v = self.send(fname)
      v = process(fname, v) if has_processor?(fname)
      if Array === v
        v = v.collect { |v2| v2.kind_of?(Storable) ? v2.to_hash : v2 } 
      end
      tmp[fname] = v.kind_of?(Storable) ? v.to_hash : v
    end
    tmp
  end
  
  def to_json(*from, &blk)
    to_hash.to_json(*from, &blk)
  end
  
  def to_yaml(*from, &blk)
    to_hash.to_yaml(*from, &blk)
  end

  def process(fname, val)
    self.send :"_storable_processor_#{fname}", val
  end
  
  def has_processor?(fname)
    self.respond_to? :"_storable_processor_#{fname}"
  end
  
  # Create a new instance of the object from YAML. 
  # +from+ a YAML String or Array (split into by line). 
  def self.from_yaml(*from)
    from_str = [from].flatten.compact.join('')
    hash = YAML::load(from_str)
    hash = from_hash(hash) if Hash === hash
    hash
  end
  
  # Create a new instance of the object from a JSON string. 
  # +from+ a YAML String or Array (split into by line). 
  def self.from_json(*from)
    from_str = [from].flatten.compact.join('')
    tmp = JSON::load(from_str)
    hash_sym = tmp.keys.inject({}) do |hash, key|
       hash[key.to_sym] = tmp[key]
       hash
    end
    hash_sym = from_hash(hash_sym) if hash_sym.kind_of?(Hash)  
    hash_sym
  end
  
  # Return the object data as a delimited string. 
  # +with_titles+ specifiy whether to include field names (default: false)
  # +delim+ is the field delimiter.
  def to_delimited(with_titles=false, delim=',')
    values = []
    field_names.each do |fname|
      values << self.send(fname.to_s)   # TODO: escape values
    end
    output = values.join(delim)
    output = field_names.join(delim) << $/ << output if with_titles
    output
  end
  # Return the object data as a tab delimited string. 
  # +with_titles+ specifiy whether to include field names (default: false)
  def to_tsv(with_titles=false)
    to_delimited(with_titles, "\t")
  end
  # Return the object data as a comma delimited string. 
  # +with_titles+ specifiy whether to include field names (default: false)
  def to_csv(with_titles=false)
    to_delimited(with_titles, ',')
  end
  # Create a new instance from tab-delimited data.  
  # +from+ a JSON string split into an array by line.
  def self.from_tsv(from=[])
    self.from_delimited(from, "\t")
  end
  # Create a new instance of the object from comma-delimited data.
  # +from+ a JSON string split into an array by line.
  def self.from_csv(from=[])
    self.from_delimited(from, ',')
  end
  
  # Create a new instance of the object from a delimited string.
  # +from+ a JSON string split into an array by line.
  # +delim+ is the field delimiter.
  def self.from_delimited(from=[],delim=',')
    return if from.empty?
    # We grab an instance of the class so we can 
    hash = {}
    
    fnames = values = []
    if (from.size > 1 && !from[1].empty?)
      fnames = from[0].chomp.split(delim)
      values = from[1].chomp.split(delim)
    else
      fnames = self.field_names
      values = from[0].chomp.split(delim)
    end
    
    fnames.each_with_index do |key,index|
      next unless values[index]
      hash[key.to_sym] = values[index]
    end
    hash = from_hash(hash) if hash.kind_of?(Hash) 
    hash
  end

  def self.read_file_to_array(path)
    contents = []
    return contents unless File.exists?(path)
    
    open(path, 'r') do |l|
      contents = l.readlines
    end

    contents
  end
  
  def self.write_file(path, content, flush=true)
    write_or_append_file('w', path, content, flush)
  end
  
  def self.append_file(path, content, flush=true)
    write_or_append_file('a', path, content, flush)
  end
  
  def self.write_or_append_file(write_or_append, path, content = '', flush = true)
    #STDERR.puts "Writing to #{ path }..." 
    create_dir(File.dirname(path))
    
    open(path, write_or_append) do |f| 
      f.puts content
      f.flush if flush;
    end
    File.chmod(0600, path)
  end
end


#################################################
# GEM: SYSINFO 0.7.3
#################################################

require 'socket'
require 'time'

# = SysInfo
# 
# A container for the platform specific system information. 
# Portions of this code were originally from Amazon's EC2 AMI tools, 
# specifically lib/platform.rb. 
class SysInfo < Storable
  unless defined?(IMPLEMENTATIONS)
    VERSION = "0.7.3".freeze
    IMPLEMENTATIONS = [
    
      # These are for JRuby, System.getproperty('os.name'). 
      # For a list of all values, see: http://lopica.sourceforge.net/os.html
      
      #regexp matcher       os        implementation
      [/mac\s*os\s*x/i,     :unix,    :osx              ],  
      [/sunos/i,            :unix,    :solaris          ], 
      [/windows\s*ce/i,     :windows, :wince            ],
      [/windows/i,          :windows, :windows          ],  
      [/osx/i,              :unix,    :osx              ],
      
      # These are for RUBY_PLATFORM and JRuby
      [/java/i,             :java,    :java             ],
      [/darwin/i,           :unix,    :osx              ],
      [/linux/i,            :unix,    :linux            ],
      [/freebsd/i,          :unix,    :freebsd          ],
      [/netbsd/i,           :unix,    :netbsd           ],
      [/solaris/i,          :unix,    :solaris          ],
      [/irix/i,             :unix,    :irix             ],
      [/cygwin/i,           :unix,    :cygwin           ],
      [/mswin/i,            :windows, :windows          ],
      [/djgpp/i,            :windows, :djgpp            ],
      [/mingw/i,            :windows, :mingw            ],
      [/bccwin/i,           :windows, :bccwin           ],
      [/wince/i,            :windows, :wince            ],
      [/vms/i,              :vms,     :vms              ],
      [/os2/i,              :os2,     :os2              ],
      [nil,                 :unknown, :unknown          ],
    ].freeze

    ARCHITECTURES = [
      [/(i\d86)/i,  :x86              ],
      [/x86_64/i,   :x86_64           ],
      [/x86/i,      :x86              ],  # JRuby
      [/ia64/i,     :ia64             ],
      [/alpha/i,    :alpha            ],
      [/sparc/i,    :sparc            ],
      [/mips/i,     :mips             ],
      [/powerpc/i,  :powerpc          ],
      [/universal/i,:x86_64           ],
      [nil,         :unknown          ],
    ].freeze
  end

  field :vm => String
  field :os => String
  field :impl => String
  field :arch => String
  field :hostname => String
  field :ipaddress_internal => String
  #field :ipaddress_external => String
  field :uptime => Float
  
  field :paths
  field :tmpdir
  field :home
  field :shell
  field :user
  field :ruby
  
  alias :implementation :impl
  alias :architecture :arch

  def initialize
    @vm, @os, @impl, @arch = find_platform_info
    @hostname, @ipaddress_internal, @uptime = find_network_info
    @ruby = RUBY_VERSION.split('.').collect { |v| v.to_i }
    @user = ENV['USER']
    require 'Win32API' if @os == :windows && @vm == :ruby
  end
  
  # Returns [vm, os, impl, arch]
  def find_platform_info
    vm, os, impl, arch = :ruby, :unknown, :unknown, :unknow
    IMPLEMENTATIONS.each do |r, o, i|
      next unless RUBY_PLATFORM =~ r
      os, impl = [o, i]
      break
    end
    ARCHITECTURES.each do |r, a|
      next unless RUBY_PLATFORM =~ r
      arch = a
      break
    end
    os == :java ? guess_java : [vm, os, impl, arch]
  end
  
  # Returns [hostname, ipaddr (internal), uptime]
  def find_network_info
    hostname, ipaddr, uptime = :unknown, :unknown, :unknown
    begin
      hostname = find_hostname
      ipaddr = find_ipaddress_internal
      uptime = find_uptime       
    rescue => ex # Be silent!
    end
    [hostname, ipaddr, uptime]
  end
  
    # Return the hostname for the local machine
  def find_hostname; Socket.gethostname; end
  
  # Returns the local uptime in hours. Use Win32API in Windows, 
  # 'sysctl -b kern.boottime' os osx, and 'who -b' on unix.
  # Based on Ruby Quiz solutions by: Matthias Reitinger 
  # On Windows, see also: net statistics server
  def find_uptime
    hours = 0
    begin
      seconds = execute_platform_specific("find_uptime") || 0
      hours = seconds / 3600 # seconds to hours
    rescue => ex
      #puts ex.message  # TODO: implement debug?
    end
    hours
  end

  
  # Return the local IP address which receives external traffic
  # from: http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
  # NOTE: This <em>does not</em> open a connection to the IP address. 
  def find_ipaddress_internal
    # turn off reverse DNS resolution temporarily 
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true   
    UDPSocket.open {|s| s.connect('65.74.177.129', 1); s.addr.last } # GitHub IP
  ensure  
    Socket.do_not_reverse_lookup = orig
  end
  
  # Returns a Symbol of the short platform descriptor in the format: VM-OS
  # e.g. <tt>:java-unix</tt>
  def platform
    "#{@vm}-#{@os}".to_sym
  end
  
  # Returns a String of the full platform descriptor in the format: VM-OS-IMPL-ARCH
  # e.g. <tt>java-unix-osx-x86_64</tt>
  def to_s(*args)
    "#{@vm}-#{@os}-#{@impl}-#{@arch}".to_sym
  end
  
    # Returns the environment paths as an Array
  def paths; execute_platform_specific(:paths); end
    # Returns the path to the current user's home directory
  def home; execute_platform_specific(:home); end
    # Returns the name of the current shell
  def shell; execute_platform_specific(:shell); end
    # Returns the path to the current temp directory
  def tmpdir; execute_platform_specific(:tmpdir); end
  
 private
  
  # Look for and execute a platform specific method. 
  # The name of the method will be in the format: +dtype-VM-OS-IMPL+.
  # e.g. find_uptime_ruby_unix_osx
  #
  def execute_platform_specific(dtype)
    criteria = [@vm, @os, @impl]
    while !criteria.empty?
      meth = [dtype, criteria].join('_').to_sym
      return self.send(meth) if SysInfo.private_method_defined?(meth)
      criteria.pop
    end
    raise "#{dtype}_#{@vm}_#{@os}_#{@impl} not implemented" 
  end
  
  def paths_ruby_unix; (ENV['PATH'] || '').split(':'); end
  def paths_ruby_windows; (ENV['PATH'] || '').split(';'); end # Not tested!
  def paths_java
    delim = @impl == :windows ? ';' : ':'
    (ENV['PATH'] || '').split(delim)
  end
  
  def tmpdir_ruby_unix; (ENV['TMPDIR'] || '/tmp'); end
  def tmpdir_ruby_windows; (ENV['TMPDIR'] || 'C:\\temp'); end
  def tmpdir_java
    default = @impl == :windows ? 'C:\\temp' : '/tmp'
    (ENV['TMPDIR'] || default)
  end
  
  def shell_ruby_unix; (ENV['SHELL'] || 'bash').to_sym; end
  def shell_ruby_windows; :dos; end
  alias_method :shell_java_unix, :shell_ruby_unix
  alias_method :shell_java_windows, :shell_ruby_windows
  
  def home_ruby_unix; File.expand_path(ENV['HOME']); end
  def home_ruby_windows; File.expand_path(ENV['USERPROFILE']); end
  def home_java
    if @impl == :windows
      File.expand_path(ENV['USERPROFILE'])
    else
      File.expand_path(ENV['HOME'])
    end
  end
  
  # Ya, this is kinda wack. Ruby -> Java -> Kernel32. See:
  # http://www.oreillynet.com/ruby/blog/2008/01/jruby_meets_the_windows_api_1.html  
  # http://msdn.microsoft.com/en-us/library/ms724408(VS.85).aspx
  # Ruby 1.9.1: Win32API is now deprecated in favor of using the DL library.
  def find_uptime_java_windows_windows
    kernel32 = com.sun.jna.NativeLibrary.getInstance('kernel32')
    buf = java.nio.ByteBuffer.allocate(256)
    (kernel32.getFunction('GetTickCount').invokeInt([256, buf].to_java).to_f / 1000).to_f
  end
  def find_uptime_ruby_windows_windows
    # Win32API is required in self.guess
    getTickCount = Win32API.new("kernel32", "GetTickCount", nil, 'L')
    ((getTickCount.call()).to_f / 1000).to_f
  end
  def find_uptime_ruby_unix_osx
    # This is faster than "who" and could work on BSD also. 
    (Time.now.to_f - Time.at(`sysctl -b kern.boottime 2>/dev/null`.unpack('L').first).to_f).to_f
  end
  
  # This should work for most unix flavours.
  def find_uptime_ruby_unix
    # who is sloooooow. Use File.read('/proc/uptime')
    (Time.now.to_i - Time.parse(`who -b 2>/dev/null`).to_f)
  end
  alias_method :find_uptime_java_unix_osx, :find_uptime_ruby_unix
  
  # Determine the values for vm, os, impl, and arch when running on Java. 
  def guess_java
    vm, os, impl, arch = :java, :unknown, :unknown, :unknown
    require 'java'
    include_class java.lang.System unless defined?(System)
    
    osname = System.getProperty("os.name")
    IMPLEMENTATIONS.each do |r, o, i|
      next unless osname =~ r
      os, impl = [o, i]
      break
    end
    
    osarch = System.getProperty("os.arch")
    ARCHITECTURES.each do |r, a|
      next unless osarch =~ r
      arch = a
      break
    end
    [vm, os, impl, arch]
  end
  
  # Returns the local IP address based on the hostname. 
  # According to coderrr (see comments on blog link above), this implementation
  # doesn't guarantee that it will return the address for the interface external
  # traffic goes through. It's also possible the hostname isn't resolvable to the
  # local IP.  
  #
  # NOTE: This code predates the current ip_address_internal. It was just as well
  # but the other code is cleaner. I'm keeping this old version here for now.
  def ip_address_internal_alt
    ipaddr = :unknown
    begin
      saddr = Socket.getaddrinfo(  Socket.gethostname, nil, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME)
      ipaddr = saddr.select{|type| type[0] == 'AF_INET' }[0][3]
    rescue => ex
    end
    ipaddr
  end
end





#################################################
# GEM: Proc Source
#################################################


require 'stringio'
require 'irb/ruby-lex'
#SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

class ProcString < String
  attr_accessor :file, :lines, :arity, :kind
  def to_proc(kind="proc")
    result = eval("#{kind} #{self}")
    result.source = self
    result
  end
  def to_lambda
    to_proc "lamda"
  end
end

class RubyToken::Token
  
    # These EXPR_BEG tokens don't have associated end tags
  FAKIES = [RubyToken::TkWHEN, RubyToken::TkELSIF, RubyToken::TkTHEN]
  
  def open_tag?
    return false if @name.nil? || get_props.nil?
    a = (get_props[1] == RubyToken::EXPR_BEG) &&
          self.class.to_s !~ /_MOD/  && # ignore onliner if, unless, etc...
          !FAKIES.member?(self.class)  
    a 
  end
  
  def get_props
    RubyToken::TkReading2Token[@name]
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
      #p [start_line, lines[0]]
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
      
      if RubyToken::TkIDENTIFIER === token
        #nothing
      elsif token.open_tag? || RubyToken::TkfLBRACE === token
        nesting += 1
        stoken = token if nesting == 1
      elsif RubyToken::TkEND === token || RubyToken::TkRBRACE === token
        if nesting == 1
          etoken = token 
          break
        end
        nesting -= 1
      elsif RubyToken::TkBITOR === token && stoken
        #nothing
      elsif RubyToken::TkNL === token && stoken && etoken
        break if nesting <= 0
      else
        #p token
      end
    end
#     puts lines if etoken.nil?
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
      when RubyToken::TkCONSTANT
        if token.instance_variable_get(:@name) == "Proc" &&
           lexer.token.is_a?(RubyToken::TkDOT)
          method = lexer.token
          if method.is_a?(RubyToken::TkIDENTIFIER) &&
             method.instance_variable_get(:@name) == "new"
            success = true
          end
        end
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

  store do |blk|
    puts "Hello Rudy1"
  end

  a = Proc.new() { |a|
    puts  "Hello Rudy2" 
  }
 
  b = Proc.new() do |b|
    puts { "Hello Rudy3" } if true
  end
  
  puts @blk.inspect, @blk.source
  puts [a.inspect, a.source]
  puts b.inspect, b.source
  
  proc = @blk.source.to_proc
  proc.call(1)
end
