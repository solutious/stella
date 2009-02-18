# From: http://codeforpeople.com/lib/ruby/timeunits/timeunits-0.0.2/lib/timeunits.rb
# ... with fix for Ruby 1.9.1

unless $__timeunits__
$__timeunits__ = File.expand_path __FILE__

  class Time
    module Units 
      VERSION = "0.0.3" # Changed from 0.0.1 (should have been 0.0.2)

      def __less__() "/" end
      def __more__() "*" end
      def microseconds() Float(self.send(__more__,(10 ** -6))) end
      def milliseconds() Float(self.send(__more__,(10 ** -3))) end
      def seconds() self end
      def minutes() seconds.send(__more__,60) end
      def hours() minutes.send(__more__,60) end
      def days() hours.send(__more__,24) end
      def weeks() days.send(__more__,7) end
      def months() weeks.send(__more__,4) end
      #def years() months.send(__more__,12) end
      def years() days.send(__more__,365) end
      def decades() years.send(__more__,10) end
      def centuries() decades.send(__more__,10) end
      instance_methods.select{|m| m !~ /__/}.each do |plural|
        singular = plural.to_s.chop # Added .to_s for 
        alias_method singular, plural
      end
    end
    module DiffUnits
      include ::Time::Units
      def __less__() "*" end
      def __more__() "/" end
    end
    alias_method "__delta__", "-" unless respond_to? "__delta__"
    def - other
      ret = __delta__ other
      ret.extend DiffUnits
      ret
    end
  end
  class Numeric
    include ::Time::Units
  end

end


if $0 == __FILE__
  require "yaml"
  require "time"

  now = Time::now

  a = now
  y 'a' => a

  b = now + 2.hours + 2.minutes
  y 'b' => b

  d = b - a
  %w( seconds minutes hours days ).each do |unit|
    y "d.#{ unit }" => d.send(unit)
  end
end
