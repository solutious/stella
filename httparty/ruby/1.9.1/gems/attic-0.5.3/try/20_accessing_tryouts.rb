require 'attic'
class ::Worker
  extend Attic
  attic :size
end

  
## save an instance variable the long way
w = Worker.new
w.metametaclass.instance_variable_set '@mattress', 'S&F'
w.metametaclass.instance_variable_get '@mattress'
#=> 'S&F'
  
## save an instance variable the short way
w = Worker.new
w.size = :california_king
w.size
#=> :california_king
  
## new instances don't cross streams
w = Worker.new
w.size
#=> nil
  
## instance variables are hidden
w = Worker.new
w.metametaclass.instance_variable_set '@mattress', 'S&F'
w.instance_variables
## []
