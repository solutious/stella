$:.unshift '../drydock/lib'
require 'drydock'

Drydock::Screen.puts '1'
Drydock::Screen.puts '2'
Drydock::Screen.puts '3'
Drydock::Screen.flush
sleep 0.5
Drydock::Screen.print '4'
Drydock::Screen.puts '5'
Drydock::Screen.flush


__END__
require 'curses'

Curses.init_screen

while 1
  Curses.insertln Time.now
  Curses.refresh
    Curses.setpos 0,0

  sleep 0.2
end