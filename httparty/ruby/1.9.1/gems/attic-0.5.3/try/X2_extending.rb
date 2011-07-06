$:.unshift './lib'
require 'attic'

class A 
  extend Attic
  attic :andy
end

class B < A
  attic :size
end

class C
  extend Attic
  attic :third
end

a, b, c = A.new, B.new, C.new

a.andy, b.andy = 1, 2

p [a.respond_to?(:andy), b.respond_to?(:andy)] # true, true
p [a.andy, b.andy]                             # 1, 2

p [a.class.attic_vars, b.class.attic_vars, c.class.attic_vars]  


