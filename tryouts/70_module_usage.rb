# ruby -Ilib tryouts/70_module_usage.rb

require 'stella'

Benelux.enable_debug

Stella.enable_quiet
#Stella.stdout.lev = 3
plan = Stella::Testplan.new('http://localhost:3114/search')
opts = {
  :hosts => '', 
  :clients => 100,
  #:duration => 10
}

#engine = Stella::Engine::Functional.new opts
engine = Stella::Engine::Load.new opts
engine.run plan

puts engine.testrun.stats[:summary].to_json