require 'stella'

## Knows a valid hostname
Stella::Utils.valid_hostname? 'localhost'
#=> true

## Knows a invalid hostname
Stella::Utils.valid_hostname? 'localhost900000000'
#=> false

## Local IP address
Stella::Utils.local_ipaddr? '127.0.0.255'
#=> true

## Private IP address (class A)
Stella::Utils.private_ipaddr? '10.0.0.255'
#=> true

## Private IP address (class C)
Stella::Utils.private_ipaddr? '172.16.0.255'
#=> true

## Private IP address (class C)
Stella::Utils.private_ipaddr? '192.168.0.255'
#=> true

