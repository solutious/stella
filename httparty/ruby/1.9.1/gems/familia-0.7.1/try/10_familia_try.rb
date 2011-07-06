require 'familia'
require 'familia/test_helpers'

## Has all redis objects
redis_objects = Familia::RedisObject.registration.keys
redis_objects.collect(&:to_s).sort
#=> ["hash", "list", "set", "string", "zset"]

## Familia created class methods for redis object class
Familia::ClassMethods.public_method_defined? :list?
#=> true

## Familia created class methods for redis object class
Familia::ClassMethods.public_method_defined? :list
#=> true

## Familia created class methods for redis object class
Familia::ClassMethods.public_method_defined? :lists
#=> true

## A Familia object knows its redis objects
Bone.redis_objects.is_a?(Hash) && Bone.redis_objects.has_key?(:owners)
#=> true

## A Familia object knows its lists
Bone.lists.size
#=> 1

## A Familia object knows if it has a list
Bone.list? :owners
#=> true

## A Familia object can get a specific redis object def
definition = Bone.list :owners
definition.klass
#=> Familia::List

## Familia.now
Familia.now Time.parse('2011-04-10 20:56:20 UTC').utc
#=> 1302468980

## Familia.qnow
Familia.qnow 10.minutes, 1302468980
#=> 1302468600

## Familia::Object.qstamp
Limiter.qstamp 10.minutes, '%H:%M', 1302468980
#=> '20:50'

## Familia::Object#qstamp
limiter = Limiter.new :request
limiter.qstamp 10.minutes, '%H:%M', 1302468980
##=> '20:50'
