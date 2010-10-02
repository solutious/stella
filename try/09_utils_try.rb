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


## Rudimentary test for binary data.
a = File.read('/usr/bin/less')
Stella::Utils.binary?(a)
#=> true

## Rudimentary test for text data
a = File.read('/etc/hosts')
Stella::Utils.binary?(a)
#=> false

## Knows a JPG
a = File.read('try/support/file.jpg')
Stella::Utils.jpg?(a)
#=>true

## Knows a GIF
a = File.read('try/support/file.gif')
Stella::Utils.gif?(a)
#=>true

## Knows a PNG
a = File.read('try/support/file.png')
Stella::Utils.png?(a)
#=>true

## Knows a BMP
a = File.read('try/support/file.bmp')
Stella::Utils.bmp?(a)
#=>true

## Knows an ICO
a = File.read('try/support/file.ico')
Stella::Utils.ico?(a)
#=>true

## Knows an image
a = File.read('try/support/file.ico')
Stella::Utils.image?(a)
#=>true

