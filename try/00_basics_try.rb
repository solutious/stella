require 'stella'

## Checkup has a mode
Stella::Engine::Checkup.mode
#=> :checkup

## Stella::Engine is aware of all available modes
Stella::Engine.modes
#=> { :checkup => Stella::Engine::Checkup }

