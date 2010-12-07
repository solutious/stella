#encoding: utf-8

$KCODE = "u" if RUBY_VERSION =~ /^1.8/


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
    field_names.collect { |field| send(field) || ((field_types[field].kind_of?(String)) ? 'unknown' : 0.0) }
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
    a = str.split(',')
    me = new
    me.update *a
  end
  def self.from_json(str)
    unpack(str)
  end
end


