#encoding: utf-8

$KCODE = "u" if RUBY_VERSION =~ /^1.8/


module Stella
  class Error < RuntimeError
    def initialize(obj=nil); @obj = obj; end
    def message; "#{self.class}: #{@obj}"; end
  end
  
  class WackyRatio < Stella::Error
  end
  
  class WackyDuration < Stella::Error
  end
  
  class InvalidOption < Stella::Error
  end
  
  class NoHostDefined < Stella::Error
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

class MatchData
  include Gibbler::String
end

class Thread
  extend Attic
  attic :stats
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





class Stella::Config < Storable
  include Gibbler::Complex

  field :source
  field :apikey
  field :secret
    
   # Returns true when the current config matches the default config
  def default?; to_hash.gibbler == DEFAULT_CONFIG_HASH; end
  
  def self.each_path(&blk)
    [PROJECT_PATH, USER_PATH].each do |path|
      Stella.ld "Loading #{path}"
      blk.call(path) if File.exists? path
    end
  end
  
  def self.refresh
    conf = {}
    Stella::Config.each_path do |path| 
      tmp = YAML.load_file path
      conf.merge! tmp if tmp
    end
    from_hash conf
  end
  
  def self.init
    raise AlreadyInitialized, PROJECT_PATH if File.exists? PROJECT_PATH
    dir = File.dirname USER_PATH
    Dir.mkdir(dir, 0700) unless File.exists? dir
    unless File.exists? USER_PATH
      Stella.li "Creating #{USER_PATH} (Add your credentials here)"
      Stella::Utils.write_to_file(USER_PATH, DEFAULT_CONFIG, 'w', 0600)
    end
    
    dir = File.dirname PROJECT_PATH
    Dir.mkdir(dir, 0700) unless File.exists? dir
    
    Stella.li "Creating #{PROJECT_PATH}"
    Stella::Utils.write_to_file(PROJECT_PATH, 'target:', 'w', 0600)
  end
  
  def self.blast
    if File.exists? USER_PATH
      Stella.li "Blasting #{USER_PATH}"
      FileUtils.rm_rf File.dirname(USER_PATH)
    end
    if File.exists? PROJECT_PATH
      Stella.li "Blasting #{PROJECT_PATH}"
      FileUtils.rm_rf File.dirname(PROJECT_PATH)
    end
  end
 
  def self.project_dir
    File.join(Dir.pwd, DIR_NAME)
  end
  
  private 
  
  def self.find_project_config
    dir = Dir.pwd.split File::SEPARATOR
    path = nil
    while !dir.empty?
      tmp = File.join(dir.join(File::SEPARATOR), DIR_NAME, 'config')
      Stella.ld " -> looking for #{tmp}"
      path = tmp and break if File.exists? tmp
      dir.pop
    end
    path ||= File.join(Dir.pwd, DIR_NAME, 'config')
    path
  end
  
  
  unless defined?(DIR_NAME)
    DIR_NAME = Stella.sysinfo.os == :windows ? 'Stella' : '.stella'
    USER_PATH = File.join(Stella.sysinfo.home, DIR_NAME, 'config')
    PROJECT_PATH = Stella::Config.find_project_config
    DEFAULT_CONFIG = <<CONF
apikey: ''
secret: ''
remote: stella.solutious.com:443
CONF
    DEFAULT_CONFIG_HASH = YAML.load(DEFAULT_CONFIG).gibbler
  end
    
  class AlreadyInitialized < Stella::Error; end
end


