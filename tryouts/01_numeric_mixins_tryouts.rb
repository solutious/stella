
#encoding: utf-8

$KCODE = "u" if RUBY_VERSION =~ /^1.8/

library :stella, 'lib'
tryouts "Numeric mixins" do
  
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


