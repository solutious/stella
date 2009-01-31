
require 'webrick'  
require 'stringio'
require 'net/dns/packet'


module Stella
  module Adapter
    # Make sure Stella's lib directory is before the system defined ones. 
    # We are using a modified version of pcaplet.rb. 
    require 'pcap'
    require 'observer'
    

    # Record HTTP or DNS events with Pcap (TCP sniffer). This requires ruby-pcap and the C pcap 
    # library as well as root acceess (TCP packet sniffing requires root privileges). If you're
    # running Ruby 1.9, JRuby, or Windows this will not be available on your system. 
    # To sniff traffic, you must be on either the machine sending the requests or the machine
    # receiving the requests. 
    class Pcap
      include Observable
      
      # Building Ruby::Pcap with Ruby 1.9.1
      # RSTRING()->len ia now RSTRING_LEN(), ... 
      #   see: http://gnufied.org/2007/12/21/mysql-c-bindings-for-ruby-19/#comment-3133
      #   see: http://www.rubyinside.com/ruby-1-9-1-preview-released-why-its-a-big-deal-1280.html#comment-37223
      # TRAP_BEG and TRAP_END are also fucked. But the fix is not clear. 
      # Basically Ruby::PCap is not ready for 1.9
      # See: http://d.hatena.ne.jp/takuma104/20080210/1202638583
      
        # Network interface device ID. eri0, en0, lo0, etc... /sbin/ifconfig -a will tell you. 
      attr_accessor :device
        # Buffer size, in bytes, to read from each packet (default: 1500)
      attr_accessor :snaplen
        # Port of the machine sending requests (default: 80)
      attr_accessor :sport
        # Port of the machine receiving requests (default: 80)
      attr_accessor :dport
        # dns or http
      attr_accessor :service
        # udp or tcp
      attr_accessor :protocol
        # Maximum number of packets to sniff
      attr_accessor :maxpacks
      
      attr_reader :pcaplet
      
      def initialize(options={})
        # The proper service name for dns is "domain"
        @service = options[:service] || 'http'
        @service = 'domain' if options[:service] == 'dns'
        
        if @service == 'domain'
          @protocol = 'udp'
        else
          @protocol = options[:protocol] || 'tcp'
        end
        
        @dport = options[:port] || Socket::getservbyname(@service)
        @sport = options[:port] || @dport
        
        @device = options[:device] || guess_device
        @snaplen = options[:snaplen] || 10000         # 10KB
        @maxpacks = options[:maxpacks] || 100_000
        
        Stella::LOGGER.info("Watching interface #{@device} for #{@service} activity on #{@protocol} port #{@dport}")
      end
      
      def guess_device
        # NOTE: This should be passed in as a value, not called from the global
        case Stella::SYSINFO.implementation
        when :osx
          "en1" # Pcap.lookupdev returns en0
        else
          Pcap.lookupdev
        end
      end
      
      def run
        
        if (respond_to? "monitor_#{@service}")
          self.send("monitor_#{@service}")
        else
          raise "Unknown service type (#{@service})"
        end
        
      end
      
      
      

      # Use Ruby-Pcap to sniff packets off the network interface. 
      #
      # DNS monitor based on: http://www.linuxjournal.com/article/9614
      # Install http://rubyforge.org/projects/net-dns
      #
      # NOTE: Is there a better way to match up a request packet with a
      # response packet?
      # We keep connect a request with the response using the domain name. 
      # It's possible that two (or more) requests to be made for the same domain 
      # at the same time and the responses could be mixed up. This will affect
      # the exact response time but probably not by much.
      def monitor_domain

        @pcaplet = Pcaplet.new(:device => @device, :count => @maxpacks)
        
        req_filter  = ::Pcap::Filter.new("#{@protocol} and dst port #{@dport}", @pcaplet.capture)
        resp_filter = ::Pcap::Filter.new("#{@protocol} and src port #{@dport}", @pcaplet.capture)
        @pcaplet.add_filter(req_filter | resp_filter)
        @pcaplet.each_packet do |packet|
          data = packet.udp_data
          case packet
          when req_filter
            dobj = Stella::Data::DomainRequest.new(data)
            dobj.time = packet.time
            dobj.client_ip = packet.ip_src
            dobj.server_ip = packet.ip_dst
            
            changed
            notify_observers(:domain_request, dobj)
            
          when resp_filter
            dobj = Stella::Data::DomainResponse.new(data)
            dobj.time = packet.time
            dobj.client_ip = packet.ip_dst
            dobj.server_ip = packet.ip_src
            
            changed
            notify_observers(:domain_response, dobj)
          end
          
        end

      rescue Interrupt
        after
        exit
      end
      

      def monitor_http
        
        @pcaplet = Pcaplet.new(:device => @device, :count => @maxpacks)
            
        begin
          req_filter  = ::Pcap::Filter.new("#{@protocol} and dst port #{@dport}", @pcaplet.capture)
          resp_filter = ::Pcap::Filter.new("#{@protocol} and src port #{@sport}", @pcaplet.capture)
          @pcaplet.add_filter(req_filter | resp_filter)
          @pcaplet.each_packet do |packet|
            data = packet.tcp_data
            next if data.nil?
            
            
            # NOTE: With HTTP 1.1 keep alive connections, multiple requests can be passed
            # through single connection. This makes it difficult to match responses with
            # requests. 
            # NOTE: We don't parse the body of POST and PUT requests because the data can
            # be (and likely is), split across numerous packets. We also only grab 1500
            # bytes from each packet. 
            # NOTE: The hostname is taken from the Host header. Requests made without 
            # this header (including HTTP 1.0) will contain the local hostname instead. 
            # TODO: resolve the hostname from the IP address.   
            # There are some helpful methods for doing some of this stuff:
            # http://www.goto.info.waseda.ac.jp/~fukusima/ruby/pcap/doc/TCPPacket.html
            case packet
            when req_filter
              next unless data and data =~ /^(GET|POST|HEAD|DELETE|PUT)\s+(.+?)\s+(HTTP.+?)$/
              dobj = Stella::Data::HTTPRequest.new(data.gsub(/\r?\n/, $/)) # Use the system's line terminators
              dobj.time = packet.time
              dobj.client_ip = packet.ip_src
              dobj.server_ip = packet.ip_dst
              
              changed
              notify_observers(:http_request, dobj)  
              
            when resp_filter
              # NOTE: Some responses do not contain a body in the first packet.
              # TODO: investigate further. Try: http://www.ruby-doc.org/core/classes/Enumerable.html
              next unless data and data =~ /^(HTTP.+)$/
              dobj = Stella::Data::HTTPResponse.new(data.gsub(/\r?\n/, $/))
              dobj.time = packet.time
              dobj.client_ip = packet.ip_dst
              dobj.server_ip = packet.ip_src
              
              changed
              notify_observers(:http_response, dobj)
                
            end
          
          end
        rescue Interrupt
          after
          exit
        rescue => ex
          Stella::LOGGER.error(ex)
        end
        
        
      end
      
      def after
      STDOUT.flush
        stat = @pcaplet.capture.stats
        if stat
          Stella::LOGGER.info("#{$/}#{stat.recv} packets received by filter");
          Stella::LOGGER.info("#{stat.drop} packets dropped by kernel", ''); # with an extra line
        end
        STDOUT.flush
        @pcaplet.capture.close
        delete_observers
      rescue
        
        # Ignore errors
      end
      
      
    end
  end
end

