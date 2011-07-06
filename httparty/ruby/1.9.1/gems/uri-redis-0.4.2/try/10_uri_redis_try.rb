require 'uri/redis'


## Default database is 0
uri = URI.parse 'redis://localhost'
[uri.db, uri.host, uri.port]
#=> [0, 'localhost', 6379]


## Can parse a redis URI with a database
uri = URI.parse 'redis://localhost/2'
[uri.db, uri.host, uri.port]
#=> [2, 'localhost', 6379]


## Can parse a key name
uri = URI.parse 'redis://localhost/2/v1:arbitrary:key'
[uri.key, uri.db, uri.host, uri.port]
#=> ['v1:arbitrary:key', 2, 'localhost', 6379]

## Can set db
uri = URI.parse 'redis://localhost/2/v1:arbitrary:key'
uri.db = 6
uri.to_s
#=> 'redis://localhost/6/v1:arbitrary:key'

## Can set key
uri = URI.parse 'redis://localhost/2/v1:arbitrary:key'
uri.key = 'v2:arbitrary:key'
uri.to_s
#=> 'redis://localhost/2/v2:arbitrary:key'