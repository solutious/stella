
# TODO: Handle nested hashes and arrays. 

module Stella
  class Storable
    NICE_TIME_FORMAT = "%Y-%m-%d@%H:%M:%S".freeze unless defined? NICE_TIME_FORMAT
      
    SupportedFormats= {
      'yaml'  => 'yml',     # format name => file extension
      'yml'   => 'yml',
      'csv'   => 'csv',
      'tsv'   => 'tsv',
      'json'  => 'json'
    }.freeze unless defined? SupportedFormats
    
    attr_reader :format
    
    def format=(v)
      raise "Unsupported format: #{v}" unless SupportedFormats.has_key?(v)
      @format = v
    end
    
    def field_names
      raise "You need to override field_names (#{self.class})"
    end
    
    def self.undump(format, file=[])
      #raise "Format not defined (#{@format})" unless self.method_defined?("to_#{@format}")
      #puts "LOAD: from_#{format}"
      send("from_#{format}", file)
    end

    
    def dump(format="yaml", with_titles=true)
      #raise "Format not defined (#{@format})" unless self.method_defined?("to_#{@format}")  
      #puts "DUMP: to_#{format}"
      self.send("to_#{format}", with_titles) 
    end
    
    def to_hash(with_titles=true)
      tmp = {}
      
      field_names.each do |fname|
        tmp[fname] = self.send(fname.to_s)
      end
      
      tmp
    end
    
    def to_yaml(with_titles=true)
      require 'yaml'
      to_hash.to_yaml
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
    
    
    def self.from_delimited(from=[],delim=',')
      return if from.empty?
      # We grab an instance of the class so we can 
      hash = {}
      
      fnames = values = []
      if (from.size > 1 && !from[1].empty?)
        fnames = from[0].chomp.split(delim)
        values = from[1].chomp.split(delim)
      else
        fnames = self.new.field_names
        values = from[0].chomp.split(delim)
      end
      
      fnames.each_with_index do |key,index|
        next unless values[index]
        number_or_string = (values[index].match(/[\d\.]+/)) ? values[index].to_f : values[index]
        hash[key.to_sym] = number_or_string
      end
      hash
    end
    def self.from_tsv(from=[])
      self.from_delimited(from, "\t")
    end
    def self.from_csv(from=[])
      self.from_delimited(from, ',')
    end
    
    def self.from_hash(from={})
      return if !from || from.empty?
      me = self.new
      fnames = me.to_hash.keys
      fnames.each do |key|
        # NOTE: this will skip generated values b/c they don't have a setter method
        me.send("#{key}=", from[key]) if self.method_defined?("#{key}=")  
      end
      me
    end
    def self.from_yaml(from=[])
      require 'yaml'
      # from is an array of strings
      from_str = from.join('')
      YAML::load(from_str)
    end
       
  end
end