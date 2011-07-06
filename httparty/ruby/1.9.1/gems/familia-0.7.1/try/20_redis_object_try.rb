
require 'familia'
require 'familia/test_helpers'
Familia.apiversion = 'v1'


## Redis Objects are unique per instance of a Familia class
@a = Bone.new 'atoken', :name1
@b = Bone.new 'atoken', :name2
@a.owners.rediskey == @b.owners.rediskey
#=> false

## Redis Objects are frozen 
@a.owners.frozen?
#=> true


## Limiter#qstamp
@limiter = Limiter.new :requests
@limiter.counter.qstamp 10.minutes, '%H:%M', 1302468980
#=> '20:50'

## Redis Objects can be stored to quantized keys
@limiter.counter.rediskey
#=> "v1:limiter:requests:counter:20:50"

## Increment counter
@limiter.counter.clear
@limiter.counter.increment
#=> 1

## Check ttl
@limiter.counter.ttl
#=> 3600

## Check ttl for a different instance
## (this exists to make sure options are cloned for each instance)
@limiter2 = Limiter.new :requests
@limiter2.counter.ttl
#=> 3600

## Check realttl
sleep 1
@limiter.counter.realttl
#=> 3600-1