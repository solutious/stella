require 'familia'
require 'familia/test_helpers'
Familia.apiversion = 'v1'

@a = Bone.new 'atoken', 'akey'

## Familia.prefix
Bone.prefix
#=> :bone

## Familia#index
@a.index
#=> 'atoken:akey'

## Familia.suffix
Bone.suffix
#=> :object

## Familia#rediskey
@a.rediskey
#=> 'v1:bone:atoken:akey:object'

## Familia#rediskey
@a.rediskey
#=> 'v1:bone:atoken:akey:object'

## Familia#save
@cust = Customer.new :delano, "Delano Mandelbaum"
@cust.save
#=> true

## Customer.instances
Customer.instances.all.collect(&:custid)
#=> [:delano]

## Familia.from_redis
obj = Customer.from_redis :delano
obj.custid
#=> :delano

## Customer.destroy
@cust.destroy!
#=> 1

## Customer.instances
Customer.instances.size
#=> 0

## Familia#save with an object that expires
obj = Session.new 'sessionid', :delano
obj.save
#=> true

## Familia.class_list
Customer.customers.class
#=> Familia::List

## Familia class rediskey
Customer.customers.rediskey
#=> 'v1:customer:customers'

## Familia.class_list
Customer.customers << :delano << :tucker << :morton
Customer.customers.size
#=> 3

## Familia class clear
Customer.customers.clear
#=> 1


## Familia class replace 1
Customer.message.value = "msg1"
#=> "msg1"

## Familia class replace 2
Customer.message.value
#=> "msg1"

## Familia class replace 3
Customer.message = "msg2"
#=> "msg2"

## Familia class replace 4
Customer.message.value
#=> "msg2"

