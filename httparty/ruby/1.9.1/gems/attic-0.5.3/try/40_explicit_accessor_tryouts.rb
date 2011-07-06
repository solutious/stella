require 'attic'

class ::Worker
  extend Attic
end
  
## can set value", 100 do
a = Worker.new
a.attic_variable_set :space, 100
a.attic_variable_get :space
#=> 100
  
## doesn't create accessor methods", false do
a = Worker.new
a.attic_variable_set :space, 100
a.respond_to? :space
#=> false