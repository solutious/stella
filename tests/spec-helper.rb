
require 'rubygems'
require 'test/spec'
require 'fileutils'

unless defined? STELLA_HOME
  STELLA_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..')) 
  $:.unshift(File.join(STELLA_HOME, 'lib')) # Make sure our local lib is first in line
end

# Stolen from http://github.com/wycats/thor
def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end

  result
end
