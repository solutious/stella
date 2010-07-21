require 'stella'

## Create testplan w/ uri
@tp = Stella::Testplan.new 'http://www.blamestella.com/'
@tp.freeze
@tp.usecases.size 
#=> 1

## has uri
@tp.first_request.id
# => '5ed1907264dcd19b0c99e38e64edfc36a92e0e3d'

## has usecase
@tp.usecases.first.id
# => 'd4584d8cb4eb1933f98910cf079181db83f41368'

## has consistent ID
@tp.id
# => '8a8c094565c37fee565c4bf57f7b10a0b240db88'


