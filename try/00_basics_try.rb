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
@run = Stella::Testrun.new @plan, :checkup, :repetitions => 3, :agent => :poop
Stella::Engine::Checkup.run @run
@report = @run.report
@report.processed?
#=> true

## Knows about errors
@report.errors?
#=> false

## Can be yaml
@report.to_yaml.size > 100
#=> true


