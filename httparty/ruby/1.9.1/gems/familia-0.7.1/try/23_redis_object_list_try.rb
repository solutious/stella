
require 'familia'
require 'familia/test_helpers'

@a = Bone.new 'atoken', 'akey'

## Familia::List#push
ret = @a.owners.push :value1
ret.class
#=> Familia::List

## Familia::List#<<
ret = @a.owners << :value2 << :value3 << :value4
ret.class
#=> Familia::List

## Familia::List#pop
@a.owners.pop
#=> 'value4'

## Familia::List#first
@a.owners.first
#=> 'value1'

## Familia::List#last
@a.owners.last
#=> 'value3'

## Familia::List#to_a
@a.owners.to_a
#=> ['value1','value2','value3']

## Familia::List#delete
@a.owners.delete 'value3'
#=> 1

## Familia::List#size
@a.owners.size
#=> 2

@a.owners.clear
