require 'attic'

## String can extend Attic
    String.extend Attic
    String.respond_to? :attic
#=> true
  
## save an instance variable the long way
s = ""
s.metametaclass.instance_variable_set '@mattress', 'S&F'
s.metametaclass.instance_variable_get '@mattress'
#=> 'S&F'

## can create attributes
String.attic :goodies
#=> [:goodies]
  
## save an instance variable the short way
s = ""
s.goodies = :california_king
p s.instance_variables
p s.attic_vars
s.goodies
#=> :california_king
  
## String instances don't cross streams
String.extend Attic
String.attic :name
a = "any"
a.name = :roger
a.name == "".name
#=> false
