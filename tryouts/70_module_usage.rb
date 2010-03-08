# ruby -Ilib tryouts/70_module_usage.rb

require 'stella'

#Benelux.enable_debug
#Stella.stdout.lev = 3

Stella.enable_quiet

plan = Stella::Testplan.new('http://localhost:3114/search')
opts = {
  :hosts => '', 
  :mode => :generate,
  :clients => 100,
  #:duration => 10
}

testrun = Stella::Testrun.new plan, opts
testrun.run

puts testrun.to_yaml