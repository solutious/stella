# ruby -Ilib tryouts/70_module_usage.rb

require 'stella'

#Stella.enable_quiet
Stella.stdout.lev = 3
plan = Stella::Testplan.new('http://localhost:3114/search')
opts = {
  :hosts => '', 
  :clients => 100,
  #:duration => 10
}
Stella::Engine::Load.run plan, opts

puts Stella::Engine::Load.testrun.stats[:summary].to_json