

YAJL_LOADED = begin   
  require 'yajl'
  true
rescue LoadError
  false
end

JSON_LOADED = begin
  require 'json' unless YAJL_LOADED
  true
rescue LoadError
  false
end

require 'yaml'
require 'fileutils'
require 'time'

unless defined?(Boolean)
  # Used in field definitions. 
  #
  #     field :name => Boolean
  #
  class Boolean; end
end

# Storable makes data available in multiple formats and can
# re-create objects from files. Fields are defined using the 
# Storable.field method which tells Storable the order and 
# name.
class Storable
  USE_ORDERED_HASH = (RUBY_VERSION =~ /^1.9/).nil?
  require 'proc_source'  
  require 'storable/orderedhash' if USE_ORDERED_HASH
  unless defined?(SUPPORTED_FORMATS) # We can assume all are defined
    VERSION = "0.8.9"
    NICE_TIME_FORMAT  = "%Y-%m-%d@%H:%M:%S".freeze 
    SUPPORTED_FORMATS = [:tsv, :csv, :yaml, :json, :s, :string].freeze 
  end
  
  @debug = false
  class << self
    attr_accessor :sensitive_fields, :field_names, :field_types, :field_opts, :debug
  end
  
  # Passes along fields to inherited classes
  def self.inherited(obj)                           
    unless Storable == self                         
      obj.sensitive_fields = self.sensitive_fields.clone if !self.sensitive_fields.nil?
      obj.field_names = self.field_names.clone if !self.field_names.nil?
      obj.field_types = self.field_types.clone if !self.field_types.nil?
    end                                             
  end                                               
    
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
  def self.field(*args, &processor)
    # TODO: Examine casting from: http://codeforpeople.com/lib/ruby/fattr/fattr-1.0.3/
    field_definitions = {}
    if args.first.kind_of?(Hash)
      args.first.each_pair do |fname,klass|
        field_definitions[fname] = { :class => klass }
      end
    else
      fname, opts = *args
      if opts.nil?
        field_definitions[fname] = {}
      elsif Hash === opts
        field_definitions[fname] = opts
      else
        raise ArgumentError, "Second argument must be a hash" 
      end
    end
    
    self.field_names ||= []
    self.field_types ||= {}
    self.field_opts ||= {}
    field_definitions.each_pair do |fname,opts|
      self.field_names << fname
      self.field_opts[fname] = opts
      self.field_types[fname] = opts[:class] unless opts[:class].nil?
      
      # This processor automatically converts a Proc object
      # to a String of its source. 
      processor = proc_processor if opts[:class] == Proc && processor.nil?
      
      unless processor.nil?
        define_method("_storable_processor_#{fname}", &processor)
      end
      
      if method_defined?(fname) # don't redefine the getter method
        STDERR.puts "method exists: #{self}##{fname}" if Storable.debug
      else
        define_method(fname) do 
          ret = instance_variable_get("@#{fname}")
          if ret.nil? 
            if opts[:default]
              ret = opts[:default]
            elsif opts[:meth]
              ret = self.send(opts[:meth])
            end
          end
          ret
        end
      end
      
      if method_defined?("#{fname}=") # don't redefine the setter methods
        STDERR.puts "method exists: #{self}##{fname}=" if Storable.debug
      else
        define_method("#{fname}=") do |val| 
          instance_variable_set("@#{fname}",val)
        end
      end
    end
  end
  
  def self.sensitive_fields(*args)
    @sensitive_fields ||= []
    @sensitive_fields.push *args unless args.empty?
    @sensitive_fields
  end
  
  def self.sensitive_field?(name)
    @sensitive_fields ||= []
    @sensitive_fields.member?(name)
  end
  
  def self.has_field?(n)
    field_names.member? n.to_sym
  end
  def has_field?(n)
    self.class.field_names.member? n.to_sym
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
  
  def sensitive?
    @storable_sensitive == true
  end
  
  def sensitive!
    @storable_sensitive = true
  end
  
  # Returns an array of field names defined by self.field
  def field_names
    self.class.field_names #|| self.class.ancestors.first.field_names
  end
  # Returns an array of field types defined by self.field. Fields that did 
  # not receive a type are set to nil.
  def field_types
    self.class.field_types #|| self.class.ancestors.first.field_types
  end
  def sensitive_fields
    self.class.sensitive_fields #|| self.class.ancestors.first.sensitive_fields
  end
  
  # Dump the object data to the given format. 
  def dump(format=nil, with_titles=false)
    format &&= format.to_sym
    format ||= :s # as in, to_s
    raise "Format not defined (#{format})" unless SUPPORTED_FORMATS.member?(format)
    send("to_#{format}") 
  end
  
  def to_string(*args)
    # TODO: sensitive?
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
    if self == Storable
      Storable::Anonymous.new from
    else
      new.from_hash(from)
    end
  end
  
  def init *args
    from_array *args
  end
  
  def initialize *args
    init *args
  end
  
  def from_array *from
    (self.field_names || []).each_with_index do |n,index|
      break if index >= from.size
      send("#{n}=", from[index])
    end
  end
  
  def self.from_array *from
    from = from.flatten.compact
    return nil if !from || from.empty?
    me = new
    me.from_array *from
    me.postprocess
    me
  end
  
  def call(fname)
    unless field_types[fname.to_sym] == Proc &&
           Proc === self.send(fname)
           raise "Field #{fname} is not a Proc"
    end
    self.instance_eval &self.send(fname)
  end
  
  def from_hash(from={})
    fnames = field_names
    
    return from if fnames.nil? || fnames.empty?
    fnames.each_with_index do |fname,index|
      ftype = field_types[fname]
      value_orig = from[fname.to_s] || from[fname.to_s.to_sym]
      next if value_orig.nil?
      
      if ( ftype == String or ftype == Symbol ) && value_orig.to_s.empty?
        value = ''
      elsif ftype == Array
        value = Array === value_orig ? value_orig : [value_orig]
      elsif ftype == Hash
        value = value_orig
      elsif !ftype.nil?
        value_orig = value_orig.first if Array === value_orig && value_orig.size == 1
        
        if    [Time, DateTime].member?(ftype)
          value = ftype.parse(value_orig)
        elsif [TrueClass, FalseClass, Boolean].member?(ftype)
          value = (value_orig.to_s.upcase == "TRUE")
        elsif ftype == Float
          value = value_orig.to_f
        elsif ftype == Integer
          value = value_orig.to_i
        elsif ftype == Symbol
          value = value_orig.to_s.to_sym
        elsif ftype == Range
          if Range === value_orig
            value = value_orig
          elsif Numeric === value_orig
            value = value_orig..value_orig
          else
            value_orig = value_orig.to_s
            if    value_orig.match(/\.\.\./)
              el = value_orig.split('...')
              value = el.first.to_f...el.last.to_f
            elsif value_orig.match(/\.\./)
              el = value_orig.split('..')
              value = el.first.to_f..el.last.to_f
            else
              value = value_orig..value_orig
            end
          end
        elsif ftype == Proc && String === value_orig
          value = Proc.from_string value_orig           
        end
      end
      
      value = value_orig if value.nil?
      
      if self.respond_to?("#{fname}=")
        self.send("#{fname}=", value) 
      else
        self.instance_variable_set("@#{fname}", value) 
      end
      
    end

    self.postprocess
    self
  end
  
  # Return the object data as a hash
  # +with_titles+ is ignored. 
  def to_hash
    preprocess if respond_to? :preprocess
    tmp = USE_ORDERED_HASH ? Storable::OrderedHash.new : {}
    if field_names
      field_names.each do |fname|
        next if sensitive? && self.class.sensitive_field?(fname)
        v = self.send(fname)
        v = process(fname, v) if has_processor?(fname)
        if Array === v
          v = v.collect { |v2| v2.kind_of?(Storable) ? v2.to_hash : v2 } 
        end
        tmp[fname] = v.kind_of?(Storable) ? v.to_hash : v
      end
    end
    tmp
  end

  def to_array
    preprocess if respond_to? :preprocess
    fields = sensitive? ? (field_names-sensitive_fields) : field_names
    fields.collect do |fname|
      next if sensitive? && self.class.sensitive_field?(fname)
      v = self.send(fname)
      v = process(fname, v) if has_processor?(fname)
      if Array === v
        v = v.collect { |v2| v2.kind_of?(Storable) ? v2.to_a : v2 } 
      end
      v
    end
  end
  
  def to_json(*from, &blk)
    preprocess if respond_to? :preprocess
    hash = to_hash
    if YAJL_LOADED # set by Storable
      ret = Yajl::Encoder.encode(hash)
      ret
    elsif JSON_LOADED
      JSON.generate(hash, *from, &blk)
    else 
      raise "no JSON parser loaded"
    end
  end
  
  def to_yaml(*from, &blk)
    preprocess if respond_to? :preprocess
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
    #from_str.force_encoding("ISO-8859-1")
    #p [:from, from_str.encoding.name] if from_str.respond_to?(:encoding)
    if YAJL_LOADED
      tmp = Yajl::Parser.parse(from_str, :check_utf8 => false)
    elsif JSON_LOADED
      tmp = JSON::load(from_str)
    else
      raise "JSON parser not loaded"
    end
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
    preprocess if respond_to? :preprocess
    values = []
    fields = sensitive? ? (field_names-sensitive_fields) : field_names
    fields.each do |fname|
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
  def self.from_tsv(from=[], sensitive=false)
    self.from_delimited(from, "\t", sensitive)
  end
  # Create a new instance of the object from comma-delimited data.
  # +from+ a JSON string split into an array by line.
  def self.from_csv(from=[], sensitive=false)
    self.from_delimited(from, ',', sensitive)
  end
  
  # Create a new instance of the object from a delimited string.
  # +from+ a JSON string split into an array by line.
  # +delim+ is the field delimiter.
  def self.from_delimited(from=[],delim=',',sensitive=false)
    return if from.empty?
    from = from.split($/) if String === from
    hash = {}
    
    fnames = sensitive ? (field_names-sensitive_fields) : field_names
    values = from[0].chomp.split(delim)
    
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
  
  class Anonymous
    def initialize from
      @hash = from
    end
    def [](key)
      @hash[meth.to_sym]
    end
    def method_missing(meth,*args)
      @hash[meth.to_sym]
    end
  end
  
end


class Storable
  # These methods can be used by Storable objects as
  # custom field processors.
  #
  # e.g.
  #
  #     class A < Storable
  #       field :name => String, &hash_proc_processor
  #     end
  #
  module DefaultProcessors
    # Replace a hash of Proc objects with a hash
    # of 
    def hash_proc_processor 
      Proc.new do |procs|
        a = {}
        unless procs.nil?
          procs.each_pair { |n,v| 
            a[n] = (Proc === v) ? v.source : v 
          }
        end
        a
      end
    end
    def proc_processor
      Proc.new do |val|
        ret = (Proc === val) ? val.source : val 
        ret
      end
    end
    # If the object already has a value for +@id+
    # use it, otherwise return the current digest.
    #
    # This allows an object to have a preset ID. 
    #
    def gibbler_id_processor
      Proc.new do |val|
        @id || self.gibbler
      end
    end
  end
  extend Storable::DefaultProcessors
end


#--
# TODO: Handle nested hashes and arrays.
# TODO: to_xml, see: http://codeforpeople.com/lib/ruby/xx/xx-2.0.0/README
# TODO: from_args([HASH or ordered params])
#++
