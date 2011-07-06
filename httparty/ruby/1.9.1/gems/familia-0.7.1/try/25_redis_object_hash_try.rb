require 'familia'
require 'familia/test_helpers'

@a = Bone.new 'atoken', 'akey'

## Familia::HashKey#has_key? knows when there's no key
@a.props.has_key? 'fieldA'
#=> false

## Familia::HashKey#[]=
@a.props['fieldA'] = '1'
@a.props['fieldB'] = '2'
@a.props['fieldC'] = '3'
#=> '3'

## Familia::HashKey#[]
@a.props['fieldA']
#=> '1'

## Familia::HashKey#has_key? knows when there's a key
@a.props.has_key? 'fieldA'
#=> true

## Familia::HashKey#all 
@a.props.all.class
#=> Hash

## Familia::HashKey#size counts the number of keys
@a.props.size
#=> 3

## Familia::HashKey#remove
@a.props.remove 'fieldB'
#=> 1

## Familia::HashKey#values
@a.props.values.sort
#=> ['1', '3']

## Familia::HashKey#increment
@a.props.increment 'counter', 100
#=> 100

## Familia::HashKey#decrement
@a.props.decrement 'counter', 60
#=> 40

## Familia::HashKey#values_at
@a.props.values_at 'fieldA', 'counter', 'fieldC'
#=> ['1', '40', '3']


@a.props.clear
