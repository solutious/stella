require 'stella'




## Knows an EC2 ip address
Stella::Utils.ec2_ipaddr?('184.73.165.118')
#=> true

## Knows a non-EC2 ip address
Stella::Utils.ec2_ipaddr?('1.2.3.4')
#=> false

## Knows an EC2 US-EAST ip address
Stella::Utils.ec2_us_east_ipaddr?('184.73.165.118')
#=> true

## Knows an EC2 US-WEST ip address
Stella::Utils.ec2_us_west_ipaddr?('50.18.62.132')
#=> true

## Knows an EC2 EU-WEST ip address
Stella::Utils.ec2_eu_west_ipaddr?('46.137.127.200')
#=> true

## Knows an EC2 AP-EAST ip address
Stella::Utils.ec2_ap_east_ipaddr?('175.41.191.200')
#=> true

## Convert EC2 cname to ip address
Stella::Utils.ec2_cname_to_ipaddr 'ec2-174-129-17-131.compute-1.amazonaws.com'
#=> '174.129.17.131'

## Knows EC2 hosted
Stella::Utils.hosted_at_ec2?('www.dotcloud.com')
#=> true

## Knows not EC2 hosted?
Stella::Utils.hosted_at_ec2?('www.rackspace.com')
#=> false

## Knows EC2 hosted east
Stella::Utils.hosted_at_ec2?('www.dotcloud.com', :us_east)
#=> true
