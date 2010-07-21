#!/usr/bin/ruby

require 'timeout'
require 'socket'
include Socket::Constants

def random_port
	1024 + rand(64511)
end

if ARGV[0].nil?
	puts "Usage: rubyroute host" ; exit 1 
end

begin
	myname = Socket.gethostname 
rescue SocketError => err_msg
	puts "Can't get my own host name (#{err_msg})." ; exit 1
end

puts "Tracing route to #{ARGV[0]}"

ttl           = 1
max_ttl       = 255
localport     = random_port
dgram_sock    = UDPSocket::new

begin
	dgram_sock.bind( myname, localport )
rescue 
	localport = random_port
	retry
end

icmp_sock     = Socket.open( Socket::PF_INET, Socket::SOCK_RAW, Socket::IPPROTO_ICMP )
icmp_sockaddr = Socket.pack_sockaddr_in( localport, myname )
icmp_sock.bind( icmp_sockaddr )

begin
	dgram_sock.connect( ARGV[0], 999 )
rescue SocketError => err_msg
	puts "Can't connect to remote host (#{err_msg})." ; exit 1
end

until ttl == max_ttl
	dgram_sock.setsockopt( 0, Socket::IP_TTL, ttl )
	dgram_sock.send( "RubyRoute says hello!", 0 )

	begin
		Timeout::timeout( 1 ) {
			data, sender = icmp_sock.recvfrom( 8192 )
			# 20th and 21th bytes of IP+ICMP datagram carry the ICMP type and code resp.
			icmp_type = data.unpack( '@20C' )[0]
			icmp_code = data.unpack( '@21C' )[0]
			# Extract the ICMP sender from response.
			puts "TTL = #{ttl}:  " + Socket.unpack_sockaddr_in( sender )[1].to_s
			if    ( icmp_type == 3 and icmp_code == 13 )
					puts "'Communication Administratively Prohibited' from this hop."
			# ICMP 3/3 is port unreachable and usually means that we've hit the target.
			elsif ( icmp_type == 3 and icmp_code == 3 )
					puts "Destination reached. Trace complete."
					exit 0
			end
		}
	rescue Timeout::Error
		puts "Timeout error with TTL = #{ttl}!"
	end

	ttl += 1
end
