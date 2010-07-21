require 'stella'

TEST_URI = 'http://bff.heroku.com/'

## Stella::Engine is aware of all available modes
Stella::Engine.modes
#=> { :checkup => Stella::Engine::Checkup }

## Checkup has a mode
Stella::Engine::Checkup.mode
#=> :checkup

## Can run checkup
@plan = Stella::Testplan.new TEST_URI
@run = Stella::Testrun.new @plan
Stella::Engine::Checkup.run @run
#=> 



