#encoding: utf-8

$KCODE = "u" if RUBY_VERSION =~ /^1.8/

class MatchData
  include Gibbler::String
end

module Addressable
  class URI
    include Gibbler::String
  end
end

class OpenStruct
  include Gibbler::Object
end


# A hash with indifferent access and magic predicates.
#
#   hash = Thor::CoreExt::HashWithIndifferentAccess.new 'foo' => 'bar', 'baz' => 'bee', 'force' => true
#
#   hash[:foo]  #=> 'bar'
#   hash['foo'] #=> 'bar'
#   hash.foo?   #=> true
#
class HashWithIndifferentAccess < ::Hash #:nodoc:

  def initialize(hash={})
    super()
    hash.each do |key, value|
      self[convert_key(key)] = value
    end
  end

  def [](key)
    super(convert_key(key))
  end

  def []=(key, value)
    super(convert_key(key), value)
  end

  def delete(key)
    super(convert_key(key))
  end

  def values_at(*indices)
    indices.collect { |key| self[convert_key(key)] }
  end

  def merge(other)
    dup.merge!(other)
  end

  def merge!(other)
    other.each do |key, value|
      self[convert_key(key)] = value
    end
    self
  end

  protected

    def convert_key(key)
      key.is_a?(Symbol) ? key.to_s : key
    end

    # Magic predicates. For instance:
    #
    #   options.force?                  # => !!options['force']
    #   options.shebang                 # => "/usr/lib/local/ruby"
    #   options.test_framework?(:rspec) # => options[:test_framework] == :rspec
    #
    def method_missing(method, *args, &block)
      method = method.to_s
      if method =~ /^(\w+)\?$/
        if args.empty?
          !!self[$1]
        else
          self[$1] == args.first
        end
      else 
        self[method]
      end
    end

end

class Symbol
  def downcase
    self.to_s.downcase.to_sym
  end
  def upcase
    self.to_s.upcase.to_sym
  end
  unless method_defined?(:empty?)
    def empty?
      self.to_s.empty?
    end
  end
end

# Fix for eventmachine in Ruby 1.9
class Thread
  unless method_defined? :kill!
    def kill!(*args) kill( *args) end
  end
end


# Assumes Time::Units and Numeric mixins are available. 
class String
  def in_seconds
    # "60m" => ["60", "m"]
    q,u = self.scan(/([\d\.]+)([s,m,h])?/).flatten
    q &&= q.to_f and u ||= 's'
    q &&= q.in_seconds(u)
  end
end


class String
  def encode_fix(enc="UTF-8")
    if RUBY_VERSION >= "1.9"
      begin
        encode!(enc, :undef => :replace, :invalid => :replace, :replace => '?')
      rescue Encoding::CompatibilityError
        BS.info "String#encode_fix: resorting to US-ASCII"
        encode!("US-ASCII", :undef => :replace, :invalid => :replace, :replace => '?')
      end
    end
    self
  end
  def plural(int=1)
    int > 1 || int.zero? ? "#{self}s" : self
  end
  def shorten(len=50)
    return self if size <= len
    self[0..len] + "..."
  end
  def to_file(filename, mode, chmod=0744)
    mode = (mode == :append) ? 'a' : 'w'
    f = File.open(filename,mode)
    f.puts self
    f.close
    raise "Provided chmod is not a Fixnum (#{chmod})" unless chmod.is_a?(Fixnum)
    File.chmod(chmod, filename)
  end
  
  # via: http://www.est1985.nl/design/2-design/96-linkify-urls-in-ruby-on-rails
  def linkify!
    self.gsub!(/\b((https?:\/\/|ftps?:\/\/|mailto:|www\.|status\.)([A-Za-z0-9\-_=%&amp;@\?\.\/]+(\/\s)?))\b/) {
      match = $1
      tail  = $3
      case match
      when /^(www|status)/     then  "<a href=\"http://#{match.strip}\">#{match}</a>"
      when /^mailto/  then  "<a href=\"#{match.strip}\">#{tail}</a>"
      else                  "<a href=\"#{match.strip}\">#{match}</a>"
      end
    }
    self
  end

  def linkify
     self.dup.linkify!
  end
  
end


unless defined?(Time::Units)
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
    
      def in_time
        Time.at(self).utc
      end
    
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

    def to_ms
      (self*1000.to_f)
    end
  
    # TODO: Use 1024?
    def to_bytes
      args = case self.abs.to_i
      when (1000)..(1000**2)
        '%3.2f%s' % [(self / 1000.to_f).to_s, 'KB']
      when (1000**2)..(1000**3)
        '%3.2f%s' % [(self / (1000**2).to_f).to_s, 'MB']
      when (1000**3)..(1000**4)
        '%3.2f%s' % [(self / (1000**3).to_f).to_s, 'GB']
      when (1000**4)..(1000**6)
        '%3.2f%s' % [(self / (1000**4).to_f).to_s, 'TB']
      else
        [self.to_i, 'B'].join
      end
    end
  end
end


# A simple class for really fast serialized timing data.
# NOTE: We're storing the serialized data directly to a
# redis sorted set so it's important that each chunk of 
# data in unique. Also, it's possible to grab the stamp 
# from the zrange using :with_scores. 
# NOTE2: We bypass Storable's #to_csv and #from_csv for 
# speed. TODO: test speed difference.
class MetricsPack < Storable
  unless defined?(MetricsPack::METRICS)
    METRICS = [:rt, :sc, :sr, :fb, :lb, :rscs, :rshs, :rqcs, :rqhs]
    TALLIES = [:n, :errors]
  end
  field :stamp => Float
  field :uid => String
  field :n => Integer
  field :rt => Float
  field :sc => Float
  field :sr => Float
  field :fb => Float
  field :lb => Float
  field :rqhs => Integer
  field :rqcs => Integer
  field :rshs => Integer
  field :rscs => Integer
  field :score => Float
  field :errors => Integer
  field :rtsd => Float # response time stdev
  def initialize(stamp=nil, uid=nil, n=nil)
    @stamp, @uid, @n = stamp, uid, n
    @stamp &&= @stamp.utc.to_i if Time === @stamp      
    self.class.field_names.each do |fname|
      self.send("#{fname}=", 0) unless fname == :id || self.send(fname)
    end                                                
    @score ||= 1.0
    @errors ||= 0
  end
  def kind
    :metric
  end
  
  # should be in the same order as the fields are defined (i.e. MetricsPack.field_names)
  def update(*args)
    field_names.each_with_index do |field,idx| 
      val = args[idx]
      val = case field_types[field].to_s
      when 'Float' 
        val.to_f
      when 'Integer'
        val.to_i
      else
        val
      end
      send("#{field}=", val)
    end
    self
  end
  
  def pack
    to_s
  end
  
  # @stamp                    => 1281355304 (2010-08-09-12-01-44)
  # quantize_stamp(1.day)     => 1281312000 (2010-08-09)
  # quantize_stamp(1.hour)    => 1281355200 (2010-08-09-12)
  # quantize_stamp(1.minute)  => 1281355260 (2010-08-09-12-01)
  def quantize_stamp(quantum)
    @stamp - (@stamp % quantum)
  end
  def to_a
    field_names.collect { |field| 
      v = send(field) 
      if v.nil?
        field_types[field] == String ? 'unknown' : 0.0
      else
        field_types[field] == Float ? v.fineround : v
      end
    }
  end
  def to_s
    to_a.join(',')
  end
  def to_csv
    to_s
  end
  def self.from_csv(str)
    unpack str
  end
  def self.unpack(str)
    return ArgumentError, "Cannot unpack nil" if str.nil?
    a = str.split(',')
    me = new
    me.update *a
  end
  def self.from_json(str)
    unpack(str)
  end
  def self.metric?(guess)
    METRICS.member?(guess.to_s.to_sym)
  end
end


#############################
# Statistics Module for Ruby
# (C) Derrick Pallas
#
# Authors: Derrick Pallas
# Website: http://derrick.pallas.us/ruby-stats/
# License: Academic Free License 3.0
# Version: 2007-10-01b
#

class Numeric
  def square ; self * self ; end
  def fineround(len=6.0)
    v = (self * (10.0**len)).round / (10.0**len)
    v.zero? ? 0 : v
  end
end

class Array
  def sum ; self.inject(0){|a,x| next if x.nil? || a.nil?; x+a} ; end
  def mean; self.sum.to_f/self.size ; end
  def median
    case self.size % 2
      when 0 then self.sort[self.size/2-1,2].mean
      when 1 then self.sort[self.size/2].to_f
    end if self.size > 0
  end
  def histogram ; self.sort.inject({}){|a,x|a[x]=a[x].to_i+1;a} ; end
  def mode
    map = self.histogram
    max = map.values.max
    map.keys.select{|x|map[x]==max}
  end
  def squares ; self.inject(0){|a,x|x.square+a} ; end
  def variance ; self.squares.to_f/self.size - self.mean.square; end
  def deviation ; Math::sqrt( self.variance ) ; end
  alias_method :sd, :deviation
  def permute ; self.dup.permute! ; end
  def permute!
    (1...self.size).each do |i| ; j=rand(i+1)
      self[i],self[j] = self[j],self[i] if i!=j
    end;self
  end
  def sample n=1 ; (0...n).collect{ self[rand(self.size)] } ; end

  def random
    self[rand(self.size)]
  end
  def percentile(perc)
    self.sort[percentile_index(perc)]
  end
  def percentile_index(perc)
    (perc * self.length).ceil - 1
  end
end


class Array
  def dump(format)
    respond_to?(:"to_#{format}") ? send(:"to_#{format}") : raise("Unknown format: #{format}")
  end
  
  def to_json
    Yajl::Encoder.encode(self)
  end
  def self.from_json(str)
    Yajl::Parser.parse(str, :check_utf8 => false)
  end
end

class Float
  
  # Returns true if a float has a fractional part; i.e. <tt>f == f.to_i</tt>
  def fractional_part?
    fractional_part != 0.0
  end
  
  # Returns the fractional part of a float. For example, <tt>(6.67).fractional_part == 0.67</tt>
  def fractional_part
    (self - self.truncate).abs
  end
  
end


class Hash
  
  unless method_defined?(:to_json)
    def to_json(*args)
      Yajl::Encoder.encode(self)
    end
  end
  
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
  
  def dump(format)
    respond_to?(:"to_#{format}") ? send(:"to_#{format}") : raise("Unknown format")
  end

  # Courtesy of Julien Genestoux
  # See: http://stackoverflow.com/questions/798710/how-to-turn-a-ruby-hash-into-http-params
  # NOTE: conflicts w/ HTTParty 0.7.3 when named "to_params"
  def to_http_params
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
          stack << ["#{parent}[#{k}]", URI::Escape.escape(v)]
        else
          params << "#{parent}[#{k}]=#{URI::Escape.escape(v)}&"
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
