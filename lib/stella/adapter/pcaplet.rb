require 'pcap'


module Stella::Adapter
  
  # Stella::Adapter::Pcaplet
  #
  # Adapted from Ruby portion of Ruby-Pcap:
  # http://www.goto.info.waseda.ac.jp/~fukusima/ruby/pcap-e.html
  # The lib/pcaplet.rb and lib/pcap_misc.rb files are in merge into this file, 
  # cleaned up and moved to the Stella::Adapter namespace. The Ruby-Pcap
  # C extension is unchanged and still required to be installed.  
  #
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
    
    def guess_device
      # NOTE: This should be passed in as a value, not called from the global
      case Stella::SYSINFO.implementation
      when :osx
        "en1" # 
      else
        Pcap.lookupdev
      end
    end
    
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

    def tcp_flags_s
      return \
	(tcp_urg? ? 'U' : '.') +
	(tcp_ack? ? 'A' : '.') +
	(tcp_psh? ? 'P' : '.') +
	(tcp_rst? ? 'R' : '.') +
	(tcp_syn? ? 'S' : '.') +
        (tcp_fin? ? 'F' : '.')
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
  IpPacket = IPPacket
  IpAddress = IPAddress
  TcpPacket = TCPPacket
  UdpPacket = UDPPacket

  # IpAddress is now obsolete.
  # New class IPAddress is implemented in C.
=begin
  class IpAddress
    def initialize(a)
      raise AurgumentError unless a.is_a?(Integer)
      @addr = a
    end

    def to_i
      return @addr
    end

    def ==(other)
      @addr == other.to_i
    end

    alias === ==
    alias eql? ==

    def to_num_s
        return ((@addr >> 24) & 0xff).to_s + "." +
          ((@addr >> 16) & 0xff).to_s + "." +
          ((@addr >> 8) & 0xff).to_s + "." +
          (@addr & 0xff).to_s;
    end

    def hostname
      addr = self.to_num_s
      # "require 'socket'" is here because of the order of
      #   ext initialization in static linked binary
      require 'socket'
      begin
	return Socket.gethostbyname(addr)[0]
      rescue SocketError
	return addr
      end
    end

    def to_s
      if Pcap.convert?
        return hostname
      else
        return to_num_s
      end
    end
  end
=end
end

class Time
  # tcpdump style format
  def tcpdump
    sprintf "%0.2d:%0.2d:%0.2d.%0.6d", hour, min, sec, tv_usec
  end
end



