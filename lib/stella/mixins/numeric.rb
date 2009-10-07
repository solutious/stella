#encoding: utf-8

$KCODE = "u" if RUBY_VERSION =~ /^1.8/

class Time
  module Units
    PER_MICROSECOND = 0.000001.freeze
    PER_MILLISECOND = 0.001.freeze
    PER_MINUTE = 60.0.freeze
    PER_HOUR = 3600.0.freeze
    PER_DAY = 86400.0.freeze
    
    def seconds()      seconds = self             end
    def minutes()      seconds * PER_MINUTE       end
    def hours()        seconds * PER_HOUR          end
    def days()         seconds * PER_DAY            end
    def weeks()        seconds * PER_DAY * 7        end
    def years()        seconds * PER_DAY * 365     end
    def microseconds() seconds * PER_MICROSECOND  end
    def milliseconds() seconds * PER_MILLISECOND  end    
    
    # Create singular methods, like hour and day. 
    instance_methods.select.each do |plural|
      singular = plural.to_s.chop
      alias_method singular, plural
    end
    
    def in_minutes()   seconds / PER_MINUTE         end
    def in_hours()     seconds / PER_HOUR         end
    def in_days()      seconds / PER_DAY         end
    def in_weeks()     seconds / PER_DAY / 7      end
    def in_years()     seconds / PER_DAY / 365      end

    alias_method :ms, :milliseconds
    alias_method :'μs', :microseconds

  end
end

class Numeric
  include Time::Units
  # TODO: Use 1024
  def to_bytes
    args = case self.abs.to_i
    when 0..1_000
      [(self).to_s, 'B']
    when 1_000..1_000_000
      [(self / 1000).to_s, 'KB']
    when 1_000_000..1_000_000_000
      [(self / (1000**2)).to_s, 'MB']
    when 1_000_000_000..1_000_000_000_000
      [(self / (1000**3)).to_s, 'GB']
    when 1_000_000_000_000..1_000_000_000_000_000
      [(self / (1000**4)).to_s, 'TB']
    else
      [self, 'B']
    end
    '%3.2f%s' % args
  end
end

