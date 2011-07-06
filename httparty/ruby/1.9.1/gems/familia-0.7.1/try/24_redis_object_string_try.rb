require 'familia'
require 'familia/test_helpers'

Familia.apiversion = 'v1'

@a = Bone.new 'atoken2', 'akey'

## Bone#rediskey
@a.rediskey
#=> 'v1:bone:atoken2:akey:object'

## Familia::String#value should give default value
@a.value.value
#=> 'GREAT!'

## Familia::String#value=
@a.value.value = "DECENT!"
#=> 'DECENT!'

## Familia::String#to_s
@a.value.to_s
#=> 'DECENT!'

## Familia::String#destroy!
@a.value.clear
#=> 1

## Familia::String.new
@ret = Familia::String.new 'arbitrary:key'
@ret.rediskey
#=> 'arbitrary:key'

## instance set
@ret.value = '1000'
#=> '1000'

## instance get
@ret.value
#=> '1000'

## Familia::String#increment
@ret.increment 
#=> 1001

## Familia::String#incrementby
@ret.incrementby 99
#=> 1100

## Familia::String#decrement
@ret.decrement 
#=> 1099

## Familia::String#decrementby
@ret.decrementby 49
#=> 1050

## Familia::String#append
@ret.append 'bytes'
#=> 9

## Familia::String#value after append
@ret.value
#=> '1050bytes'


@ret.clear
