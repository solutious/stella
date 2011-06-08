require 'socket'  # Why doesn't socket work with autoload?
autoload :Timeout, 'timeout'
autoload :IPAddr, 'ipaddr'
autoload :Whois, 'whois'
autoload :PublicSuffixService, 'public_suffix_service'

class Stella
  
  IMAGE_EXT = %w/.bmp .gif .jpg .jpeg .png .ico/ unless defined?(Stella::IMAGE_EXT)
  
  # A motley collection of methods that Stella loves to call!
  module Utils
    extend self
    include Socket::Constants

    ADDR_LOCAL = IPAddr.new("127.0.0.0/8")
    ADDR_CLASSA = IPAddr.new("10.0.0.0/8")
    ADDR_CLASSB = IPAddr.new("172.16.0.0/16")
    ADDR_CLASSC = IPAddr.new("192.168.0.0/24")
    
    # See: https://forums.aws.amazon.com/ann.jspa?annID=877
    ADDR_EC2_US_EAST = %w{
      216.182.224.0/20
      72.44.32.0/19
      67.202.0.0/18
      75.101.128.0/17
      174.129.0.0/16
      204.236.192.0/18
      184.73.0.0/16
      184.72.128.0/17
      184.72.64.0/18
      50.16.0.0/15
    }.collect { |ipr| IPAddr.new(ipr.strip) }
    
    ADDR_EC2_US_WEST = %w{
      204.236.128.0/18
      184.72.0.0/18
      50.18.0.0/18
    }.collect { |ipr| IPAddr.new(ipr.strip) }
    
    ADDR_EC2_EU_WEST = %w{
      79.125.0.0/17
      46.51.128.0/18
      46.51.192.0/20
      46.137.0.0/17
    }.collect { |ipr| IPAddr.new(ipr.strip) }
    
    ADDR_EC2_AP_EAST = %w{
      175.41.128.0/18
      122.248.192.0/18
    }.collect { |ipr| IPAddr.new(ipr.strip) }
    
    
    def image_ext?(name)
      IMAGE_EXT.include?(File.extname(name.downcase))
    end
    
    def image?(s)
      return false if s.nil?
      (bmp?(s) || jpg?(s) || png?(s) || gif?(s) || ico?(s))
    end
    
    # Checks if the file has more than 30% non-ASCII characters.
    # NOTE: how to determine the difference between non-latin and binary?
    def binary?(s)
      return false if s.nil?
      #puts "TODO: fix encoding issue in 1.9"
      s = s.to_s.split(//) rescue [] unless Array === s
      s.slice!(0, 4096)  # limit to a typcial blksize
      ((s.size - s.grep(" ".."~").size) / s.size.to_f) > 0.30
    end
    
    # Based on ptools by Daniel J. Berger 
    # http://raa.ruby-lang.org/project/ptools/
    def bmp?(a)
      possible = ['BM6', 'BM' << 226.chr]
      possible.member? a.slice(0, 3)
    end

    # Based on ptools by Daniel J. Berger 
    # http://raa.ruby-lang.org/project/ptools/
    def jpg?(a)
      a.slice(0, 10) == "\377\330\377\340\000\020JFIF"
    end

    # Based on ptools by Daniel J. Berger 
    # http://raa.ruby-lang.org/project/ptools/
    def png?(a)
      a.slice(0, 4) == "\211PNG"
    end

    def ico?(a)
      a.slice(0, 3) == [0.chr, 0.chr, 1.chr].join
    end

    # Based on ptools by Daniel J. Berger 
    # http://raa.ruby-lang.org/project/ptools/
    def gif?(a)
      ['GIF89a', 'GIF97a'].include?(a.slice(0, 6))
    end
    
    def domain(host)
      begin
        PublicSuffixService.parse host
      rescue PublicSuffixService::DomainInvalid => ex
        Stella.ld ex.message
        nil
      rescue => ex
        Stella.li "Error determining domain for #{host}: #{ex.message} (#{ex.class})"
        Stella.ld ex.backtrace
        nil
      end
    end
    
    def whois(host_or_ip)
      begin
        raw = Whois.whois(host_or_ip)
        info = raw.content.split("\n").select { |line| line !~ /\A[\#\%]/ && !line.empty? }
        info.join("\n")
      rescue => ex
        Stella.ld "Error fetching whois for #{host_or_ip}: #{ex.message}"
        Stella.ld ex.backtrace
      end
    end
    
    # Returns an Array of ip addresses or nil
    def ipaddr(host)
      require 'resolv'
      host = host.host if host.kind_of?(URI)
      begin
        resolv = Resolv::DNS.new # { :nameserver => [] }
        resolv.getaddresses(host).collect { |addr| addr.to_s }
      rescue => ex
        Stella.ld "Error getting ip address for #{host}: #{ex.message} (#{ex.class})"
        Stella.ld ex.backtrace
        nil
      end
    end
    
    # http://www.opensource.apple.com/source/ruby/ruby-4/ruby/lib/resolv.rb
    # * Resolv::DNS::Resource::IN::ANY
    # * Resolv::DNS::Resource::IN::NS
    # * Resolv::DNS::Resource::IN::CNAME
    # * Resolv::DNS::Resource::IN::SOA
    # * Resolv::DNS::Resource::IN::HINFO
    # * Resolv::DNS::Resource::IN::MINFO
    # * Resolv::DNS::Resource::IN::MX
    # * Resolv::DNS::Resource::IN::TXT
    # * Resolv::DNS::Resource::IN::ANY
    # * Resolv::DNS::Resource::IN::A
    # * Resolv::DNS::Resource::IN::WKS
    # * Resolv::DNS::Resource::IN::PTR
    # * Resolv::DNS::Resource::IN::AAAA
    
    # Returns a cname or nil
    def cname(host)
      require 'resolv'
      host = host.host if host.kind_of?(URI)
      begin
        resolv = Resolv::DNS.new # { :nameserver => [] }
        resolv.getresources(host, Resolv::DNS::Resource::IN::CNAME).collect { |cname| cname.name.to_s }.first
      rescue => ex
        Stella.ld "Error getting CNAME for #{host}: #{ex.message} (#{ex.class})"
        Stella.ld ex.backtrace
        nil
      end
    end
    
    def local_ipaddr?(addr)
      addr = IPAddr.new(addr) if String === addr
      ADDR_LOCAL.include?(addr)
    end
     
    def private_ipaddr?(addr)
      addr = IPAddr.new(addr) if String === addr
      ADDR_CLASSA.include?(addr) ||
      ADDR_CLASSB.include?(addr) ||
      ADDR_CLASSC.include?(addr)
    end
    
    def ec2_cname_to_ipaddr(cname)
      return unless cname =~ /\Aec2-(\d+)-(\d+)-(\d+)-(\d+)\./
      [$1, $2, $3, $4].join '.'
    end
    
    def ec2_ipaddr?(addr)
      ec2_us_east_ipaddr?(addr) || ec2_us_west_ipaddr?(addr) ||
      ec2_eu_west_ipaddr?(addr) || ec2_ap_east_ipaddr?(addr)
    end
    
    def ec2_us_east_ipaddr?(addr)
      ADDR_EC2_US_EAST.each { |ipclass| return true if ipclass.include?(addr) }
      false
    end
    def ec2_us_west_ipaddr?(addr)
      ADDR_EC2_US_WEST.each { |ipclass| return true if ipclass.include?(addr) }
      false
    end
    def ec2_eu_west_ipaddr?(addr)
      ADDR_EC2_EU_WEST.each { |ipclass| return true if ipclass.include?(addr) }
      false
    end
    def ec2_ap_east_ipaddr?(addr)
      ADDR_EC2_AP_EAST.each { |ipclass| return true if ipclass.include?(addr) }
      false
    end
    
    def hosted_at_ec2?(hostname, region=nil)
      meth = region.nil? ? :ec2_ipaddr? : :"ec2_#{region}_ipaddr?"
      cname = Stella::Utils.cname(hostname)
      if !cname.nil? && cname.first
        addr = Stella::Utils.ec2_cname_to_ipaddr(cname.first)
      else
        addresses = Stella::Utils.ipaddr(hostname) || []
        addr = addresses.first
      end
      addr.nil? ? false : Stella::Utils.send(meth, addr)
    end
    
    def valid_hostname?(uri)
      begin 
        if String === uri
          uri = "http://#{uri}" unless uri.match(/^https?:\/\//)
          uri = URI.parse(uri)
        end
        hostname = Socket.gethostbyname(uri.host).first
        true
      rescue SocketError => ex
        Stella.ld "#{uri.host}: #{ex.message}"
        false
      end
    end
    
    # Return the external IP address (the one seen by the internet)
    def external_ip_address
      ip = nil
      begin
        %w{solutious.heroku.com/ip}.each do |sponge|
          ipstr = Net::HTTP.get(URI.parse("http://#{sponge}")) || ''
          ip = /([0-9]{1,3}\.){3}[0-9]{1,3}/.match(ipstr).to_s
          break if ip && !ip.empty?
        end
      rescue SocketError, Errno::ETIMEDOUT => ex
        Stella.le "Connection Error. Check your internets!"
      end
      ip
    end
    
    # Return the local IP address which receives external traffic
    # from: http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
    # NOTE: This <em>does not</em> open a connection to the IP address. 
    def internal_ip_address
      # turn off reverse DNS resolution temporarily 
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true   
      ip = UDPSocket.open {|s| s.connect('75.101.137.7', 1); s.addr.last } # Solutious IP
      ip
    ensure  
      Socket.do_not_reverse_lookup = orig
    end
    
    
    # <tt>require</tt> a glob of files. 
    # * +path+ is a list of path elements which is sent to File.join 
    # and then to Dir.glob. The list of files found are sent to require. 
    # Nothing is returned but LoadError exceptions are caught. The message
    # is printed to STDERR and the program exits with 7. 
    def require_glob(*path)
      begin
        Dir.glob(File.join(*path.flatten)).each do |path|
          require path
        end
      rescue LoadError => ex
        puts "Error: #{ex.message}"
        exit 7
      end
    end
    
    
    # <tt>require</tt> a library from the vendor directory.
    # The vendor directory should be organized such
    # that +name+ and +version+ can be used to create
    # the path to the library. 
    #
    # e.g.
    # 
    #     vendor/httpclient-2.1.5.2/httpclient
    #
    def require_vendor(name, version)
       $:.unshift File.join(STELLA_LIB_HOME, '..', 'vendor', "#{name}-#{version}")
       require name
    end
    
    # Same as <tt>require_vendor</tt>, but uses <tt>autoload</tt> instead.
    def autoload_vendor(mod, name, version)
      autoload mod, File.join(STELLA_LIB_HOME, '..', 'vendor', "#{name}-#{version}", name)
    end
    
    # Checks whether something is listening to a socket. 
    # * +host+ A hostname
    # * +port+ The port to check
    # * +wait+ The number of seconds to wait for before timing out. 
    #
    # Returns true if +host+ allows a socket connection on +port+. 
    # Returns false if one of the following exceptions is raised:
    # Errno::EAFNOSUPPORT, Errno::ECONNREFUSED, SocketError, Timeout::Error
    #
    def service_available?(host, port, wait=3)
      if Stella.sysinfo.vm == :java
        begin
          iadd = Java::InetSocketAddress.new host, port      
          socket = Java::Socket.new
          socket.connect iadd, wait * 1000  # milliseconds
          success = !socket.isClosed && socket.isConnected
        rescue NativeException => ex
          puts ex.message, ex.backtrace if Stella.debug?
          false
        end
      else 
        begin
          status = Timeout::timeout(wait) do
            socket = Socket.new( AF_INET, SOCK_STREAM, 0 )
            sockaddr = Socket.pack_sockaddr_in( port, host )
            socket.connect( sockaddr )
          end
          true
        rescue Errno::EAFNOSUPPORT, Errno::ECONNREFUSED, SocketError, Timeout::Error => ex
          puts ex.class, ex.message, ex.backtrace if Stella.debug?
          false
        end
      end
    end
    
    # A basic file writer
    def write_to_file(filename, content, mode, chmod=0600)
      mode = (mode == :append) ? 'a' : 'w'
      f = File.open(filename,mode)
      f.puts content
      f.close
      return unless Stella.sysinfo.os == :unix
      raise "Provided chmod is not a Fixnum (#{chmod})" unless chmod.is_a?(Fixnum)
      File.chmod(chmod, filename)
    end

    # 
    # Generates a string of random alphanumeric characters.
    # * +len+ is the length, an Integer. Default: 8
    # * +safe+ in safe-mode, ambiguous characters are removed (default: true):
    #       i l o 1 0
    def strand( len=8, safe=true )
       chars = ("a".."z").to_a + ("0".."9").to_a
       chars.delete_if { |v| %w(i l o 1 0).member?(v) } if safe
       str = ""
       1.upto(len) { |i| str << chars[rand(chars.size-1)] }
       str
    end
    
    # Returns +str+ with the leading indentation removed. 
    # Stolen from http://github.com/mynyml/unindent/ because it was better.
    def noindent(str)
      indent = str.split($/).each {|line| !line.strip.empty? }.map {|line| line.index(/[^\s]/) }.compact.min
      str.gsub(/^[[:blank:]]{#{indent}}/, '')
    end
    
    
    IPAddr.new("127.0.0.0/8")
    
  end
end