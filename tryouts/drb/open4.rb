$: << '/usr/jruby-1.1.6/lib/ruby/gems/1.8/gems/open4-0.9.6/lib/'


require "open4"


pid, stdin, stdout, stderr = Open4::popen4 "sh"

stdin.puts "echo 42.out"
stdin.puts "echo 42.err 1>&2"
stdin.close

ignored, status = Process::waitpid2 pid

puts "pid        : #{ pid }"
puts "stdout     : #{ stdout.read.strip }"
puts "stderr     : #{ stderr.read.strip }"
puts "status     : #{ status.inspect }"
puts "exitstatus : #{ status.exitstatus }"
