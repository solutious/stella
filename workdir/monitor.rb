#!/usr/bin/env ruby

STELLA_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$: << File.join(STELLA_HOME, 'lib')

require "stella"
#require "stella/command/monitor"


# Building Ruby::Pcap with Ruby 1.9.1
# RSTRING()->len ia now RSTRING_LEN(), ... 
#   see: http://gnufied.org/2007/12/21/mysql-c-bindings-for-ruby-19/#comment-3133
#   see: http://www.rubyinside.com/ruby-1-9-1-preview-released-why-its-a-big-deal-1280.html#comment-37223
# TRAP_BEG and TRAP_END are also fucked. But the fix is not clear. 
# Basically Ruby::PCap is not ready for 1.9

#monitor = Stella::Monitor.new()
require 'pcaplet'



# Finds the ethernet device
dev = Pcap.lookupdev

httpdump = Pcaplet.new('-s 1500 -i en1')


HTTP_REQUEST  = Pcap::Filter.new('tcp and dst port 80', httpdump.capture)
HTTP_RESPONSE = Pcap::Filter.new('tcp and src port 80', httpdump.capture)
counter = 0
httpdump.add_filter(HTTP_REQUEST | HTTP_RESPONSE)
httpdump.each_packet {|pkt|
  data = pkt.tcp_data
  s= nil
  
  case pkt
  when HTTP_REQUEST
    if data and data =~ /^(GET.+?)$/
      path = $1
      host = pkt.dst.to_s
      host << ":#{pkt.dport}" if pkt.dport != 80
      s = data
      counter += 1
      puts "#{counter} " << data
    end
  when HTTP_RESPONSE
    if data and data =~ /^([A-Z].+)$/
      status = $1
      s = data
      next unless s
      #  puts s if s
      #puts "-------------RESPONSE"
    end  
  end
  STDOUT.flush
}

at_exit {
  puts "#{counter} GET requests"
}
__END__
# DNS monitor from: http://www.linuxjournal.com/article/9614
# Install http://rubyforge.org/projects/net-dns
require 'net/dns/packet'

dev = Pcap.lookupdev
capture = Pcap::Capture.open_live( "en1", 1500 )
capture.setfilter( 'udp port 53' )
NUMPACKETS = 50
puts "#{Time.now} - BEGIN run."
capture.loop( NUMPACKETS ) do |packet|
  dns_data = Net::DNS::Packet.parse( packet.udp_data )
  # Iterate over additional RRs
  
  dns_header = dns_data.header
  if dns_header.query? then
    print "Device #{packet.ip_src} (to #{packet.ip_dst}) looking for "
    question = dns_data.question
    question.inspect =~ /^\[(.+)\s+IN/
    puts $1
    puts dns_data.header.inspect
    puts dns_data.question.inspect
    STDOUT.flush
  else
    puts "ANSWER: #{dns_data.answer.inspect}"
  end
  
  STDOUT.flush
end

capture.close
puts "#{Time.now} - END run."


__END__
