require 'attic'
  
## can extend Attic
class ::Worker
  extend Attic
  def kind() :true end
end
# 1.9                             # 1.8
Worker.methods.member?(:attic) || Worker.methods.member?('attic')
#=> true
  
## can't include Attic raises exception
begin
  class ::Worker
    include Attic
  end
rescue => RuntimeError
  :success
end
#=> :success

## can define attic attribute
Worker.attic :size
w = Worker.new
#w.attic :size
p Worker.instance_methods(false)
p Worker.methods.sort
w.respond_to? :size
#=> true 
  
## can access attic attributes explicitly"
w = Worker.new
w.attic_variable_set :size, 2
w.attic_variable_get :size
#=> 2
  
## won't define a method if on already exists
Worker.attic :kind
a = Worker.new
a.kind
#=> :true
