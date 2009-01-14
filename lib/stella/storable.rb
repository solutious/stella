
# TODO: Handle nested hashes and arrays. 

require 'yaml'
require 'utils/fileutil'

module Stella
  class Storable
    NICE_TIME_FORMAT  = "%Y-%m-%d@%H:%M:%S".freeze unless defined? NICE_TIME_FORMAT
    SUPPORTED_FORMATS = %w{tsv csv yaml json}.freeze unless defined? SUPPORTED_FORMATS
    
    attr_reader :format
    
    def format=(v)
      raise "Unsupported format: #{v}" unless SUPPORTED_FORMATS.member?(v)
      @format = v
    end
    
    def init
      self.class.send(:class_variable_set, :@@field_names, []) unless class_variable_defined?(:@@field_names)
      self.class.send(:class_variable_set, :@@field_types, []) unless class_variable_defined?(:@@field_types)
    end
      
    def self.field(args={})
      
        args = {args => nil} unless args.is_a? Hash

      args.each_pair do |m,t|
        
        [[:@@field_names, m], [:@@field_types, t]].each do |tuple|
          class_variable_set(tuple[0], []) unless class_variable_defined?(tuple[0])
          class_variable_set(tuple[0], class_variable_get(tuple[0]) << tuple[1])
        end
        
        next if method_defined?(m)
        
        # NOTE: I need a way to put these in the caller's namespace... Here's they're shared by all
        # the subclasses which is not helpful. It will likely involve Kernel#caller and binding. 
        # Maybe class_eval, wraped around def field. 

        
        define_method(m) do instance_variable_get("@#{m}") end
        
        define_method("#{m}=") do |val| 
          instance_variable_set("@#{m}",val)
        end
      end
    end
    
    def self.field_names
      class_variable_get(:@@field_names)
    end
    def self.field_types
      class_variable_get(:@@field_types)
    end
    
    def field_names
      self.class.send(:class_variable_get, :@@field_names)
    end
    
    def field_types
      self.class.send(:class_variable_get, :@@field_types)
    end
    
    def format=(v)
      raise "Unsupported format: #{v}" unless SUPPORTED_FORMATS.member?(v)
      @format = v
    end

    
    def dump(format=nil, with_titles=true)
      format ||= @format
      raise "Format not defined (#{format})" unless SUPPORTED_FORMATS.member?(format)
      send("to_#{format}", with_titles) 
    end
    
    def self.from_file(file_path=nil, format=nil)
      raise "Cannot read file (#{file_path})" unless File.exists?(file_path)
      format = format || File.extname(file_path).tr('.', '')
      me = send("from_#{format}", FileUtil.read_file_to_array(file_path))
      me.format = format
      me
    end
    def to_file(file_path=nil, with_titles=true)
      raise "Cannot store to nil path" if file_path.nil?
      format = File.extname(file_path).tr('.', '')
      format ||= @format
      FileUtil.write_file(file_path, dump(format, with_titles))
    end
  

    def self.from_hash(from={})
      me = self.new
    
      return me if !from || from.empty?
      
      fnames = field_names
      fnames.each_with_index do |key,index|
        
        value = from[key]
        
        # TODO: Correct this horrible implementation (sorry, me. It's just one of those days.)
        
        if field_types[index] == Time
          value = Time.parse(from[key].to_s)
        elsif field_types[index] == DateTime
          value = DateTime.parse(from[key].to_s)
        elsif field_types[index] == TrueClass
          value = (from[key].to_s == "true")
        elsif field_types[index] == Float
          value = from[key].to_f
        elsif field_types[index] == Integer
          value = from[key].to_i
        end
        
        me.send("#{key}=", value) if self.method_defined?("#{key}=")  
      end
      me
    end
    def to_hash(with_titles=true)
      tmp = {}
      field_names.each do |fname|
        tmp[fname] = self.send(fname)
      end
      tmp
    end
    

    def self.from_yaml(from=[])
      # from is an array of strings
      from_str = from.join('')
      hash = YAML::load(from_str)
      hash = from_hash(hash) if hash.is_a? Hash 
      hash
    end
    def to_yaml(with_titles=true)
      to_hash.to_yaml
    end
    

    def self.from_json(from=[])
      require 'json'
      # from is an array of strings
      from_str = from.join('')
      tmp = JSON::load(from_str)
      hash_sym = tmp.keys.inject({}) do |hash, key|
         hash[key.to_sym] = tmp[key]
         hash
      end
      hash_sym = from_hash(hash_sym) if hash_sym.is_a? Hash  
      hash_sym
    end
    def to_json(with_titles=true)
      require 'json'
      to_hash.to_json
    end
    
    def to_delimited(with_titles=false, delim=',')
      values = []
      field_names.each do |fname|
        values << self.send(fname.to_s)   # TODO: escape values
      end
      output = values.join(delim)
      output = field_names.join(delim) << $/ << output if with_titles
      output
    end
    def to_tsv(with_titles=false)
      to_delimited(with_titles, "\t")
    end
    def to_csv(with_titles=false)
      to_delimited(with_titles, ',')
    end
    def self.from_tsv(from=[])
      self.from_delimited(from, "\t")
    end
    def self.from_csv(from=[])
      self.from_delimited(from, ',')
    end
    
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
      hash = from_hash(hash) if hash.is_a? Hash 
      hash
    end

  
  end
end
