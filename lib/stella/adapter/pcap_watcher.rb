


module Stella
  module Adapter
    # Make sure Stella's lib directory is before the system defined ones. 
    # We are using a modified version of pcaplet.rb. 
    require 'pcaplet'
    require 'observer'
    
    # Stella::Adapter::PcapWatcher
    #
    # Record HTTP or DNS events with Pcap (TCP sniffer). This requires ruby-pcap and the C pcap 
    # library as well as root acceess (TCP packet sniffing requires root privileges). If you're
    # running Ruby 1.9, JRuby, or Windows this will not be available on your system. 
    # To sniff traffic, you must be on either the machine sending the requests or the machine
    # receiving the requests. 
    class PcapWatcher
      include Observable
      
      # Building Ruby::Pcap with Ruby 1.9.1
      # RSTRING()->len ia now RSTRING_LEN(), ... 
      #   see: http://gnufied.org/2007/12/21/mysql-c-bindings-for-ruby-19/#comment-3133
      #   see: http://www.rubyinside.com/ruby-1-9-1-preview-released-why-its-a-big-deal-1280.html#comment-37223
      # TRAP_BEG and TRAP_END are also fucked. But the fix is not clear. 
      # Basically Ruby::PCap is not ready for 1.9
      
      
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
        service = (options[:service] == 'dns') ? 'domain' : options[:service]
        
        @service = service || 'http'
        @protocol = options[:protocol] || (@service == 'dns') ? 'udp' : 'tcp'
        
        @dport = options[:port] || Socket::getservbyname(@service)
        @sport = options[:port] || @dport
        
        @device = options[:device] || guess_device
        @snaplen = options[:snaplen] || 1500
        @maxpacks = options[:maxpacks] || 100000
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
        
        @service == 'domain' ? monitor_dns : monitor_http
        
      end
      
      def monitor_generic
        
        
      end
      
      
      # monitor_dns
      #
      # Use Ruby-Pcap to sniff packets off the network interface. 
      #
      # NOTE: Is there a better way to match up a request packet with a
      # response packet?
      # We keep connect a request with the response using the domain name. 
      # It's possible that two (or more) requests to be made for the same domain 
      # at the same time and the responses could be mixed up. This will affect
      # the exact response time but probably not by much.
      def monitor_dns
        require 'net/dns/packet'

        @pcaplet = Pcaplet.new(:device => @device)
        
        lookup = {}
        req_counter = 0
        packet_counter = 0
        
        at_exit { puts "#{$/}Requests: #{req_counter}"; puts "Packets: #{packet_counter} of #{@maxpacks}" }
        
        
        req_filter  = Pcap::Filter.new('udp port 53', @pcaplet.capture)
        @pcaplet.add_filter(req_filter)
        @pcaplet.capture.loop(@maxpacks) do |packet|
          
          dns_data = Net::DNS::Packet.parse( packet.udp_data )
          dns_header = dns_data.header
          domain_name = dns_data.question[0].qName
          
          packet_counter += 1
          
          # This is an outgoing DNS request
          if dns_header.query? then
            req_counter += 1
            lookup[domain_name] ||= {}
            
            lookup[domain_name][:counter] ||= 0
            lookup[domain_name][:counter] += 1
            lookup[domain_name][:ip_src] = packet.ip_src.to_s
            lookup[domain_name][:ip_dsr] = packet.ip_dst.to_s
            lookup[domain_name][:target] = domain_name
            lookup[domain_name][:request_time] = packet.time.to_f
          
          # This is an incoming DNS response
          else
            domain_name = dns_data.answer[0].name
            lookup[domain_name] ||= {}
            lookup[domain_name][:counter] ||= 0
            lookup[domain_name][:counter] += 1
            lookup[domain_name][:response_time] = packet.time.to_f
            
            # Empty the lists if they are already populated
            lookup[domain_name][:address] = []
            lookup[domain_name][:cname] = []
            
            # Store the CNAMEs associated to this domain. Can be empty. 
            dns_data.each_cname do |cname|
              lookup[domain_name][:cname] << cname.to_s
            end
            
            # Store the IP address for this domain. If empty, the lookup was unsuccessful. 
            dns_data.each_address do |ip|
              lookup[domain_name][:address] << ip.to_s
            end
            
          end
          
          if defined?(lookup[domain_name][:request_time]) && defined?(lookup[domain_name][:response_time])
            changed
            notify_observers('domain', lookup) 
          end
          
          STDOUT.flush
        end

        @pcaplet.capture.close
      end
      
      def after
        delete_observers
        @pcaplet.capture.close
      rescue
        # Ignore errors
      end
      
      def monitor_http
        require 'webrick'  
        require 'stringio'
        require 'pp'
        
        @pcaplet = Pcaplet.new(:device => @device)
        
        req_counter = 0
        packet_counter = 0
        resp_counter = 0
        req = {}
        
        at_exit { puts "#{$/}Requests: #{req_counter}"; puts "Packets: #{packet_counter} of #{@maxpacks}" }
        require 'pp'
        begin
          req_filter  = Pcap::Filter.new('tcp and dst port 80', @pcaplet.capture)
          resp_filter = Pcap::Filter.new('tcp and src port 80', @pcaplet.capture)
          @pcaplet.add_filter(req_filter | resp_filter)
          @pcaplet.capture.loop(@maxpacks) do |packet|
            data = packet.tcp_data
            packet_counter += 1
          
          
            # NOTE: With HTTP 1.1 keep alive connections, multiple requests can be passed
            # through single connection. This makes it difficult to match responses with
            # requests. For now, we're just recording the requests in the order they're
            # made. We'll parse the response in later versions. 
            # NOTE: We don't parse the body of POST and PUT requests because the data can
            # be (and likely is), split across numerous packets. We also only grab 1500
            # bytes from each packet. If you're interested in this feature, let us know
            # stella@solutious.com. 
            case packet
            when req_filter
              
              if data and data =~ /^(GET|POST|HEAD|DELETE|PUT)\s+(.+?)\s+(HTTP.+?)$/
                req_counter += 1
                req = {}
                req[:packet_time] = packet.time.to_f
                req[:address] = packet.dst.to_s
                
                server_parsed = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
                begin
                  server_parsed.parse(StringIO.new(data.to_s))
                  %w{query header request_time request_method cookies}.each do |key|
                    req[key.to_sym] = server_parsed.send(key.to_s)
                  end
                  req[:header].delete("cookie") # we store cookie in req[:cookie]
                  
                rescue => ex
                  Stella::LOGGER.debug(ex.message)
                ensure
                  changed
                  notify_observers('http', server_parsed)
                end

              end
            #when resp_filter
            #  if data and data =~ /^([HTTP].+)$/
            #    req[:resp] ||= {} 
            #    req[:resp][:status] = $1
            #    req[:resp][:data] = data
            #    pp data
            #    puts
            #  end  
            end
          
          end
        rescue => ex
          Stella::LOGGER.error(ex)
        end
        
        
        
      end
    end
  end
end
