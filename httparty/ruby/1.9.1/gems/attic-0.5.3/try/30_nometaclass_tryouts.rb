require 'attic'
  
## has list of no metaclass classes
Object::NOMETACLASS
#=> [Symbol, Fixnum]
  
## Symbol metaclass raises exception
begin
  :any.metaclass
rescue NoMetaClass
  :success
end
#=> :success
  
## Symbol instances don't cross streams
Symbol.extend Attic
Symbol.attic :name
a, b = :symbol1, :symbol2
a.name = :roger
[a.name, b.name]
#=> [:roger, nil]
  
## metaclass? method exists
Symbol.extend Attic
:any.respond_to? :metaclass?
#=> true
  
## metaclass? method is false for a Symbol", false do
:any.metaclass?
#=> false

## A Symbol's attic vars appear in all_instance_variables" do
Symbol.extend Attic
Symbol.attic :name
a, b = :symbol1, :symbol2
a.name = :roger
a.all_instance_variables
#=> [:@___attic_name]
  

## A Symbol's attic vars do not appear in instance_variables" do
Symbol.extend Attic
Symbol.attic :name
a, b = :symbol1, :symbol2
a.name = :roger
a.instance_variables
#=> []  
  
## knows attic variables", [:name] do
Symbol.attic_variables
#=> [:name]