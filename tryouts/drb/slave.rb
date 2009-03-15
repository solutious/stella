
# See: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/227105
# See: http://jsgoecke.wordpress.com/2009/01/30/using-drb-with-adhearsion/
# See: http://docs.adhearsion.com/display/adhearsion/Using+DRb

$: << 'lib'

require 'rubygems'
require 'slave'
#
# simple usage is simply to stand up a server object as a slave.  you do not
# need to wait for the server, join it, etc.  it will die when the parent
# process dies - even under 'kill -9' conditions
#
  class Server
    def add_two n
      n + 2
    end
  end

  slave = Slave.new :object => Server.new

  server = slave.object
  p server.add_two(40) #=> 42

  slave.shutdown
sleep 20