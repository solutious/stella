require 'stella'

TEST_URI = 'http://www.blamestella.com/'

## Create testplan w/ uri
@tp = Stella::Testplan.new TEST_URI
@tp.id
#=> '8a8c094565c37fee565c4bf57f7b10a0b240db88'

## has consistent usecase ID
@tp.usecases.first.id
# => 'd4584d8cb4eb1933f98910cf079181db83f41368'

## can access first request
@tp.first_request.id
# => '5ed1907264dcd19b0c99e38e64edfc36a92e0e3d'

## Request is http
@tp.first_request.protocol
#=> :http

## Stella instance
@stella = Stella.new TEST_URI
@stella.plan.id
#=> @tp.id

## Create testrun
@tr = Stella::Testrun.new @tp
@tr.id.class
#=> Gibbler::Digest

## Default testrun status is new
@tr.new?
#=> true

## Testrun status can be set
@tr.running!
@tr.running?
#=> true

## Testplan can go to JSON
@tp.to_json.gibbler
#=> '0ab2adb8bb0ef26ecc66480b7d40f02114b0309b'

## Can come back from JSON
@tr2 = Stella::Testrun.from_json @tr.to_json
@tr2.id
#=> @tr.id

