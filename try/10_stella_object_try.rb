require 'stella'

TEST_URI = 'http://www.blamestella.com/'

## Create testplan w/ uri
@tp = Stella::Testplan.new TEST_URI
@tp.id
#=> '9c7d56020ffa632dd1c798a6ee1990a656d59b59'

## has consistent usecase ID
@tp.usecases.first.id
# => '77b98a7a840c8f58bc51a8fdb07874a4ecb752a3'

## can access first request
@tp.first_request.id
# => '8cb1d7467eb28ae519bbbc448911b617e5e40130'

## Request is http
@tp.first_request.protocol
#=> :http

## Stella instance
@stella = Stella.new TEST_URI
@stella.plan.planid
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
@tp.to_json
##=> ''

## Can come back from JSON
@tr2 = Stella::Testrun.from_json @tr.to_json
@tr2.id
#=> @tr.id

