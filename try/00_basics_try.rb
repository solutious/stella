require 'stella'

TEST_URI = 'http://www.yellowpages.ca/search/si/1/food/richmond'

## Stella::Engine is aware of all available modes
Stella::Engine.modes
#=> { :checkup => Stella::Engine::Checkup }

## Checkup has a mode
Stella::Engine::Checkup.mode
#=> :checkup

## Can run checkup
@plan = Stella::Testplan.new TEST_URI
@run = Stella::Testrun.new @plan, :checkup
@report = Stella::Engine::Checkup.run @run
@report.processed?
#=> true

## Knows about errors
p @report.section[:content].title
@report.errors?
#=> false

## Can be yaml
@report.to_yaml.size > 100
#=> true


