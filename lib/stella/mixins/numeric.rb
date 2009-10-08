#encoding: utf-8

$KCODE = "u" if RUBY_VERSION =~ /^1.8/

class Time
  module Units
    PER_MICROSECOND = 0.000001.freeze
    PER_MILLISECOND = 0.001.freeze
    PER_MINUTE = 60.0.freeze
    PER_HOUR = 3600.0.freeze
    PER_DAY = 86400.0.freeze
    
    def microseconds() seconds * PER_MICROSECOND    end
    def milliseconds() seconds * PER_MILLISECOND   end
    def seconds()      self                        end
    def minutes()      seconds * PER_MINUTE         end
    def hours()        seconds * PER_HOUR            end
    def days()         seconds * PER_DAY              end
    def weeks()        seconds * PER_DAY * 7          end
    def years()        seconds * PER_DAY * 365       end 
    
    def in_minutes()   seconds / PER_MINUTE       end
    def in_hours()     seconds / PER_HOUR       end
    def in_days()      seconds / PER_DAY       end
    def in_weeks()     seconds / PER_DAY / 7    end
    def in_years()     seconds / PER_DAY / 365    end
      
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

