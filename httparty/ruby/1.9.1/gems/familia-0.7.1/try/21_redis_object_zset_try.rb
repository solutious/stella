require 'familia'
require 'familia/test_helpers'

@a = Bone.new 'atoken', 'akey'

## Familia::SortedSet#add
@a.metrics.add 2, :metric2
@a.metrics.add 4, :metric4
@a.metrics.add 0, :metric0
@a.metrics.add 1, :metric1
@a.metrics.add 3, :metric3
#=> true

## Familia::SortedSet#members
@a.metrics.members
#=> ['metric0', 'metric1', 'metric2', 'metric3', 'metric4']

## Familia::SortedSet#members
@a.metrics.revmembers
#=> ['metric4', 'metric3', 'metric2', 'metric1', 'metric0']

## Familia::SortedSet#rank
@a.metrics.rank 'metric1'
#=> 1

## Familia::SortedSet#revrank
@a.metrics.revrank 'metric1'
#=> 3

## Familia::SortedSet#rangebyscore
@a.metrics.rangebyscore 1, 3
#=> ['metric1', 'metric2', 'metric3']

## Familia::SortedSet#rangebyscore with a limit
@a.metrics.rangebyscore 1, 3, :limit => [0, 2]
#=> ['metric1', 'metric2']

## Familia::SortedSet#increment
@a.metrics.increment 'metric4', 100
#=> 104

## Familia::SortedSet#decrement
@a.metrics.decrement 'metric4', 50
#=> 54

## Familia::SortedSet#score
@a.metrics.score 'metric4'
#=> 54

## Familia::SortedSet#remrangebyscore
@a.metrics.remrangebyscore 3, 100
#=> 2

## Familia::SortedSet#members after remrangebyscore
@a.metrics.members
#=> ['metric0', 'metric1', 'metric2']

## Familia::SortedSet#remrangebyrank
@a.metrics.remrangebyrank 0, 1
#=> 2

## Familia::SortedSet#members after remrangebyrank
@a.metrics.members
#=> ['metric2']

@a.metrics.clear