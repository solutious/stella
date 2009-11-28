$:.unshift 'lib'
require 'stella'

l = Stella::Data::Logger.new
l.info "hihi"
l.flush

#
#
def 