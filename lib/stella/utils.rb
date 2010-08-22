
require 'socket'  # Why doesn't socket work with autoload?
autoload :Timeout, 'timeout'
autoload :IPAddr, 'ipaddr'

class Stella
  
  IMAGE_EXT = %w/.bmp .gif .jpg .jpeg .png .ico/ unless defined?(Stella::IMAGE_EXT)
  
  # A motley collection of methods that Stella loves to call!
  module Utils
    extend self
    include Socket::Constants

    @addr_local = IPAddr.new("127.0.0.0/8")
    @addr_classA = IPAddr.new("10.0.0.0/8")
    @addr_classB = IPAddr.new("172.16.0.0/16")
    @addr_classC = IPAddr.new("192.168.0.0/24")
    
    def image_ext?(name)
      IMAGE_EXT.include?(File.extname(name.downcase))
    end
    
    def image?(contents)
       (bmp?(contents) || jpg?(contents) || png?(contents) || gif?(contents) || ico?(contents))
    end
    
    # Checks if the file has more than 30% non-ASCII characters.
    # NOTE: how to determine the difference between non-latin and binary?
    def binary?(s)
      s = s.to_s.split(//) unless Array === s
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
    
    
    def ipaddr(host)
      host = host.host if host.kind_of?(URI)
      begin
        Socket::getaddrinfo(host, "echo", Socket::AF_INET, Socket::SOCK_DGRAM)[0][3]
      rescue => ex
        Stella.ld "Error getting ip address for #{host}: #{ex.message} (#{ex.class})"
        Stella.ld ex.backtrace
        nil
      end
    end

    def local_ipaddr?(addr)
      addr = IPAddr.new(addr) if String === addr
      @addr_local.include?(addr)
    end
     
    def private_ipaddr?(addr)
      addr = IPAddr.new(addr) if String === addr
      @addr_classA.include?(addr) ||
      @addr_classB.include?(addr) ||
      @addr_classC.include?(addr)
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
    
  end
end