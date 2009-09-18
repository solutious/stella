dir = ::File.expand_path(::File.dirname(__FILE__))
require ::File.join(dir, 'example_webapp.rb')
run Sinatra::Application