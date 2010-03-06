# ruby -Ilib tryouts/70_module_usage.rb

require 'stella'

Stella.enable_debug
Stella.stdout.lev = 2


#plan = Stella::Testplan.new('/', '/search')
plan = Stella::Testplan.load_file 'examples/essentials/plan.rb'
Stella::Engine::Load.run plan, :hosts => 'http://localhost:3114'