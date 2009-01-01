
require 'stella/adapter/pcaplet'

module Stella
  module Adapter
    
    # Stella::Adapter::PcapRecorder
    #
    # Record HTTP or DNS events with Pcap (TCP sniffer). This requires ruby-pcap and the C pcap 
    # library as well as root acceess (TCP packet sniffing requires root privileges). If you're
    # running Ruby 1.9, JRuby, or Windows this will not be available on your system. 
    # To sniff traffic, you must be on either the machine sending the requests or the machine
    # receiving the requests. 
    class PcapRecorder
      
      # Building Ruby::Pcap with Ruby 1.9.1
      # RSTRING()->len ia now RSTRING_LEN(), ... 
      #   see: http://gnufied.org/2007/12/21/mysql-c-bindings-for-ruby-19/#comment-3133
      #   see: http://www.rubyinside.com/ruby-1-9-1-preview-released-why-its-a-big-deal-1280.html#comment-37223
      # TRAP_BEG and TRAP_END are also fucked. But the fix is not clear. 
      # Basically Ruby::PCap is not ready for 1.9
      
      
        # Network interface device ID. eri0, en0, lo0, etc... /sbin/ifconfig -a will tell you. 
      attr_accessor :device
        # Buffer size, in bytes, to read from each packet (default: 1500)
      attr_accessor :buffer
        # Port of the machine sending requests (default: 80)
      attr_accessor :sport
        # Port of the machine receiving requests (default: 80)
      attr_accessor :dport
        # :dns or :http
      attr_accessor :service
      
      def initialize
        @device ||= guess_device
      end
      
      def guess_device
        
      end
      
      def run
        monitor_http
        #monitor_dns
        
      end
      
      def monitor_dns
        require 'net/dns/packet'

        
        capture = Pcap::Capture.open_live( "en1", 1500 )
        capture.setfilter( 'udp port 53' )
        numpackets = 50
        puts "#{Time.now} - BEGIN run."
        capture.loop( numpackets ) do |packet|
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
      end
      def monitor_http

        # device defaults. OS X: en1, Linux: , Solaris: eri0?
        httpdump = Stella::Adapter::Pcaplet.new
        req  = Pcap::Filter.new('tcp and dst port 80', httpdump.capture)
        resp = Pcap::Filter.new('tcp and src port 80', httpdump.capture)
        counter = 0
        httpdump.add_filter(req | resp)
        httpdump.each_packet {|pkt|
          data = pkt.tcp_data
          s= nil

          case pkt
          when req
            if data and data =~ /^(GET.+?)$/
              path = $1
              host = pkt.dst.to_s
              host << ":#{pkt.dport}" if pkt.dport != 80
              s = data
              counter += 1
              puts "#{counter} " << data
            end
          when resp
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
      end
    end
  end
end
