require 'pcap'


# Pcaplet
#
# Adapted from Ruby portion of Ruby-Pcap:
# http://www.goto.info.waseda.ac.jp/~fukusima/ruby/pcap-e.html
# The lib/pcaplet.rb and lib/pcap_misc.rb files are in merge into this file
# and cleaned up. The Ruby-Pcap C extension is unchanged and still required 
# to be installed.  
# We specifically removed the dependency on ARGV and OptParse. It was messy
# and required ARGV to be specifically modified before requiring this package. 
# Manual: http://www.goto.info.waseda.ac.jp/~fukusima/ruby/pcap/doc/index.html
class Pcaplet

  attr_accessor :debug, :verbose
    # do not convert address to name
  attr_accessor :convert
  attr_accessor :device, :rfile, :count, :snaplen, :filter

  def initialize(args = {})
  
    @debug   = args[:debug]   || false
    @verbose = args[:verbose] || false
    @device = args[:device] || guess_device
    @rfile = args[:rfile]
    @convert = args[:convert] || false
    @count   = args[:count].to_i
    @snaplen = args[:snaplen].to_i > 0 ? args[:snaplen] : 1500
    @filter = args[:filter] || ''
  
    Pcap.convert = @convert
  
    # check option consistency
    usage(1) if @device && @rfile
    if !@device and !@rfile
      @device = Pcap.lookupdev
    end

    # open
    begin
      if @device
        @capture = Pcap::Capture.open_live(@device, @snaplen)
      elsif @rfile
        if @rfile !~ /\.gz$/
          @capture = Capture.open_offline(@rfile)
        else
          $stdin = IO.popen("gzip -dc < #@rfile", 'r')
          @capture = Capture.open_offline('-')
        end
      end
      @capture.setfilter(@filter)
      rescue Pcap::PcapError, ArgumentError
        $stdout.flush
        $stderr.puts $!
        exit(1)
      end
    end

  attr('capture')


  def add_filter(f)
    if @filter == nil || @filter =~ /^\s*$/  # if empty
      @filter = f
    else
      f = f.source if f.is_a? Filter
      @filter = "( #{@filter} ) and ( #{f} )"
    end
      @capture.setfilter(@filter)
  end

  def each_packet(&block)
    begin
      duplicated = (RUBY_PLATFORM =~ /linux/ && @device == "lo")
      unless duplicated
        @capture.loop(@count, &block)
      else
        flip = true
        @capture.loop(@count) do |pkt|
          flip = (! flip)
          next if flip
          block.call pkt
        end
      end
    rescue Interrupt
      $stdout.flush
      $stderr.puts("Interrupted.")
      $stderr.puts $@.join("\n\t") if $DEBUG
    ensure
      # print statistics if live
      if @device
        stat = @capture.stats
        if stat
          $stderr.print("#{stat.recv} packets received by filter\n");
          $stderr.print("#{stat.drop} packets dropped by kernel\n");
        end
      end
    end
  end

  alias each each_packet

  def close
    @capture.close
  end
end



module Pcap
  class Packet
    def to_s
      'Some packet'
    end

    def inspect
      "#<#{type}: #{self}>"
    end
  end

  class IPPacket
    def to_s
      "#{ip_src} > #{ip_dst}"
    end
  end

  class TCPPacket
    def tcp_data_len
      ip_len - 4 * (ip_hlen + tcp_hlen)
    end
    
    # The 3-way handshake that initiates a request
    # ....S. --->
    # .A..S. <---
    # .A.... --->
    #
    # The teardown procedure at the end of the request
    # .A...F --->
    # .A.... <---
    # .A...F --->
    # .A.... <...
    def tcp_flags_s
      return \
	      (tcp_urg? ? 'U' : '.') +  # Urgent
	      (tcp_ack? ? 'A' : '.') +  # ACKnowledgement: Successful transfer
	      (tcp_psh? ? 'P' : '.') +  # Push
	      (tcp_rst? ? 'R' : '.') +  # Reset
	      (tcp_syn? ? 'S' : '.') +  # SYNchronization: this is the first segment in a new transaction
        (tcp_fin? ? 'F' : '.')    # FINal: final transaction
    end

    def to_s
      "#{src}:#{sport} > #{dst}:#{dport} #{tcp_flags_s}"
    end
  end

  class UDPPacket
    def to_s
      "#{src}:#{sport} > #{dst}:#{dport} len #{udp_len} sum #{udp_sum}"
    end
  end

  class ICMPPacket
    def to_s
      "#{src} > #{dst}: icmp: #{icmp_typestr}"
    end
  end

  #
  # Backword compatibility
  #
  IpPacket = IPPacket unless defined? IpPacket
  IpAddress = IPAddress unless defined? IpAddress
  TcpPacket = TCPPacket unless defined? TcpPacket
  UdpPacket = UDPPacket unless defined? UdpPacket

end

class Time
  # tcpdump style format
  def tcpdump
    sprintf "%0.2d:%0.2d:%0.2d.%0.6d", hour, min, sec, tv_usec
  end
end



