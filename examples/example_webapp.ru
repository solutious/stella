# Stella Demo Rackup
#
# Usage:
# 
#     $ thin -R examples/example_webapp.ru -p 3114 start

dir = ::File.expand_path(::File.dirname(__FILE__))
require ::File.join(dir, 'example_webapp.rb')
run Sinatra::Application