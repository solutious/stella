
require 'familia'
require 'familia/test_helpers'

@a = Bone.new 'atoken', 'akey'

## Familia::Set#add
ret = @a.tags.add :a
ret.class
#=> Familia::Set

## Familia::Set#<<
ret = @a.tags << :a << :b << :c
ret.class
#=> Familia::Set

## Familia::Set#members
@a.tags.members.sort
#=> ['a', 'b', 'c']

## Familia::Set#member? knows when a value exists
@a.tags.member? :a
#=> true

## Familia::Set#member? knows when a value doesn't exist
@a.tags.member? :x
#=> false

## Familia::Set#member? knows when a value doesn't exist
@a.tags.size
#=> 3


@a.tags.clear
