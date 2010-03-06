# ruby -Ilib tryouts/70_module_usage.rb

require 'stella'

Stella.enable_quiet

plan = Stella::Testplan.new('/')
opts = {
  :hosts => 'http://localhost:3114', 
  :clients => 100,
  #:duration => 10
}
Stella::Engine::Load.run plan, opts

puts Stella::Engine::Load.testrun.stats[:summary].to_json