
#encoding: utf-8
$KCODE = "u" if RUBY_VERSION =~ /^1.8/

group "Numeric mixins"
library :stella, 'lib'

tryouts "Natural language" do
  
  drill "base == 1.hour", 1.hour, 3600
  drill "1.milliseconds", 1.milliseconds, 0.001
  drill "1.microseconds", 1.microseconds, 0.000001
  drill "10.minutes / 60.seconds", 10.minutes / 60.seconds, 10
  drill "1.day", 1.day, 86400
  drill "1.year == 365.days", 1.year, 31536000
  drill "1.week == 7.days", 1.week, 604800
  drill "1.week == 186.hours", 1.week, 168.hours

  drill "60.in_minutes", 60.in_minutes, 1
  drill "3600.in_hours", 3600.in_hours, 1
  drill "5400.in_hours", 5400.in_hours, 1.5
  drill "604800.in_days", 604800.in_days, 7
  
  drill "60.hours - 1.day", 60.hours - 1.day, 129600.0
  drill "1.year - 5.days", 1.year - 5.days, 31104000.0
  
  drill "100 - 90", 100 - 90, 10.seconds
  drill "90 + 9", 51 + 9, 1.minute
  
end


tryouts "Bytes" do
  drill "1000 == 1000.00B", 1000.to_bytes, "1000.00B"
  drill "1010", 1010.to_bytes, "1.01KB"
  drill "1020100", (1010 ** 2).to_bytes, "1.02MB"
  drill "1030301000", (1010 ** 3).to_bytes, "1.03GB"
  drill "1040604010000", (1010 ** 4).to_bytes, "1.04TB"
end

