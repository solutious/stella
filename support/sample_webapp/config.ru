# Stella Sample Web Application
#
# This application plays nicely with the example
# test plans (see examples/).
#
# Usage:
# 
#     $ thin -R support/sample_webapp/config.ru -p 3114 start

dir = ::File.expand_path(::File.dirname(__FILE__))
require ::File.join(dir, 'app.rb')
run Sinatra::Application