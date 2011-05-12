require 'stella'

@base_uri = "http://bff.heroku.com/"

## can get a URI
ret = Stella.get(@base_uri)
ret.class
#=> String

## can checkup on a URI
ret = Stella.checkup @base_uri
ret.class
#=> Stella::Report
