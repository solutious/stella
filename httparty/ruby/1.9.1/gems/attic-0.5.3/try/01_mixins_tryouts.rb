require 'attic'

## has metaclass", 'Object' do
if Tryouts.sysinfo.ruby.to_s == "1.9.1"
  Object.new.metaclass.superclass.to_s
else
  'Object'
end
#=> 'Object'

## has metametaclass", '#<Class:Object>' do
if Tryouts.sysinfo.ruby.to_s >= "1.9.1"
  Object.new.metaclass.superclass.to_s
else
  '#<Class:Object>'
end
#=> 'Object'
