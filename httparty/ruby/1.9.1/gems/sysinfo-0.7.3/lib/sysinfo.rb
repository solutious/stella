require 'socket'
require 'storable'
require 'time'

# = SysInfo
# 
# A container for the platform specific system information. 
# Portions of this code were originally from Amazon's EC2 AMI tools, 
# specifically lib/platform.rb. 
class SysInfo < Storable
  unless defined?(IMPLEMENTATIONS)
    VERSION = "0.7.3".freeze
    IMPLEMENTATIONS = [
    
      # These are for JRuby, System.getproperty('os.name'). 
      # For a list of all values, see: http://lopica.sourceforge.net/os.html
      
      #regexp matcher       os        implementation
      [/mac\s*os\s*x/i,     :unix,    :osx              ],  
      [/sunos/i,            :unix,    :solaris          ], 
      [/windows\s*ce/i,     :windows, :wince            ],
      [/windows/i,          :windows, :windows          ],  
      [/osx/i,              :unix,    :osx              ],
      
      # These are for RUBY_PLATFORM and JRuby
      [/java/i,             :java,    :java             ],
      [/darwin/i,           :unix,    :osx              ],
      [/linux/i,            :unix,    :linux            ],
      [/freebsd/i,          :unix,    :freebsd          ],
      [/netbsd/i,           :unix,    :netbsd           ],
      [/solaris/i,          :unix,    :solaris          ],
      [/irix/i,             :unix,    :irix             ],
      [/cygwin/i,           :unix,    :cygwin           ],
      [/mswin/i,            :windows, :windows          ],
      [/djgpp/i,            :windows, :djgpp            ],
      [/mingw/i,            :windows, :mingw            ],
      [/bccwin/i,           :windows, :bccwin           ],
      [/wince/i,            :windows, :wince            ],
      [/vms/i,              :vms,     :vms              ],
      [/os2/i,              :os2,     :os2              ],
      [nil,                 :unknown, :unknown          ],
    ].freeze

    ARCHITECTURES = [
      [/(i\d86)/i,  :x86              ],
      [/x86_64/i,   :x86_64           ],
      [/x86/i,      :x86              ],  # JRuby
      [/ia64/i,     :ia64             ],
      [/alpha/i,    :alpha            ],
      [/sparc/i,    :sparc            ],
      [/mips/i,     :mips             ],
      [/powerpc/i,  :powerpc          ],
      [/universal/i,:x86_64           ],
      [nil,         :unknown          ],
    ].freeze
  end

  field :vm => String
  field :os => String
  field :impl => String
  field :arch => String
  field :hostname => String
  field :ipaddress_internal => String
  #field :ipaddress_external => String
  field :uptime => Float
  
  field :paths
  field :tmpdir
  field :home
  field :shell
  field :user
  field :ruby
  
  alias :implementation :impl
  alias :architecture :arch

  def initialize
    @vm, @os, @impl, @arch = find_platform_info
    @hostname, @ipaddress_internal, @uptime = find_network_info
    @ruby = RUBY_VERSION.split('.').collect { |v| v.to_i }
    @user = ENV['USER']
    require 'Win32API' if @os == :windows && @vm == :ruby
  end
  
  # Returns [vm, os, impl, arch]
  def find_platform_info
    vm, os, impl, arch = :ruby, :unknown, :unknown, :unknow
    IMPLEMENTATIONS.each do |r, o, i|
      next unless RUBY_PLATFORM =~ r
      os, impl = [o, i]
      break
    end
    ARCHITECTURES.each do |r, a|
      next unless RUBY_PLATFORM =~ r
      arch = a
      break
    end
    os == :java ? guess_java : [vm, os, impl, arch]
  end
  
  # Returns [hostname, ipaddr (internal), uptime]
  def find_network_info
    hostname, ipaddr, uptime = :unknown, :unknown, :unknown
    begin
      hostname = find_hostname
      ipaddr = find_ipaddress_internal
      uptime = find_uptime       
    rescue => ex # Be silent!
    end
    [hostname, ipaddr, uptime]
  end
  
    # Return the hostname for the local machine
  def find_hostname; Socket.gethostname; end
  
  # Returns the local uptime in hours. Use Win32API in Windows, 
  # 'sysctl -b kern.boottime' os osx, and 'who -b' on unix.
  # Based on Ruby Quiz solutions by: Matthias Reitinger 
  # On Windows, see also: net statistics server
  def find_uptime
    hours = 0
    begin
      seconds = execute_platform_specific("find_uptime") || 0
      hours = seconds / 3600 # seconds to hours
    rescue => ex
      #puts ex.message  # TODO: implement debug?
    end
    hours
  end

  
  # Return the local IP address which receives external traffic
  # from: http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
  # NOTE: This <em>does not</em> open a connection to the IP address. 
  def find_ipaddress_internal
    # turn off reverse DNS resolution temporarily 
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true   
    UDPSocket.open {|s| s.connect('65.74.177.129', 1); s.addr.last } # GitHub IP
  ensure  
    Socket.do_not_reverse_lookup = orig
  end
  
  # Returns a Symbol of the short platform descriptor in the format: VM-OS
  # e.g. <tt>:java-unix</tt>
  def platform
    "#{@vm}-#{@os}".to_sym
  end
  
  # Returns a String of the full platform descriptor in the format: VM-OS-IMPL-ARCH
  # e.g. <tt>java-unix-osx-x86_64</tt>
  def to_s(*args)
    "#{@vm}-#{@os}-#{@impl}-#{@arch}".to_sym
  end
  
    # Returns the environment paths as an Array
  def paths; execute_platform_specific(:paths); end
    # Returns the path to the current user's home directory
  def home; execute_platform_specific(:home); end
    # Returns the name of the current shell
  def shell; execute_platform_specific(:shell); end
    # Returns the path to the current temp directory
  def tmpdir; execute_platform_specific(:tmpdir); end
  
 private
  
  # Look for and execute a platform specific method. 
  # The name of the method will be in the format: +dtype-VM-OS-IMPL+.
  # e.g. find_uptime_ruby_unix_osx
  #
  def execute_platform_specific(dtype)
    criteria = [@vm, @os, @impl]
    while !criteria.empty?
      meth = [dtype, criteria].join('_').to_sym
      return self.send(meth) if SysInfo.private_method_defined?(meth)
      criteria.pop
    end
    raise "#{dtype}_#{@vm}_#{@os}_#{@impl} not implemented" 
  end
  
  def paths_ruby_unix; (ENV['PATH'] || '').split(':'); end
  def paths_ruby_windows; (ENV['PATH'] || '').split(';'); end # Not tested!
  def paths_java
    delim = @impl == :windows ? ';' : ':'
    (ENV['PATH'] || '').split(delim)
  end
  
  def tmpdir_ruby_unix; (ENV['TMPDIR'] || '/tmp'); end
  def tmpdir_ruby_windows; (ENV['TMPDIR'] || 'C:\\temp'); end
  def tmpdir_java
    default = @impl == :windows ? 'C:\\temp' : '/tmp'
    (ENV['TMPDIR'] || default)
  end
  
  def shell_ruby_unix; (ENV['SHELL'] || 'bash').to_sym; end
  def shell_ruby_windows; :dos; end
  alias_method :shell_java_unix, :shell_ruby_unix
  alias_method :shell_java_windows, :shell_ruby_windows
  
  def home_ruby_unix; File.expand_path(ENV['HOME']); end
  def home_ruby_windows; File.expand_path(ENV['USERPROFILE']); end
  def home_java
    if @impl == :windows
      File.expand_path(ENV['USERPROFILE'])
    else
      File.expand_path(ENV['HOME'])
    end
  end
  
  # Ya, this is kinda wack. Ruby -> Java -> Kernel32. See:
  # http://www.oreillynet.com/ruby/blog/2008/01/jruby_meets_the_windows_api_1.html  
  # http://msdn.microsoft.com/en-us/library/ms724408(VS.85).aspx
  # Ruby 1.9.1: Win32API is now deprecated in favor of using the DL library.
  def find_uptime_java_windows_windows
    kernel32 = com.sun.jna.NativeLibrary.getInstance('kernel32')
    buf = java.nio.ByteBuffer.allocate(256)
    (kernel32.getFunction('GetTickCount').invokeInt([256, buf].to_java).to_f / 1000).to_f
  end
  def find_uptime_ruby_windows_windows
    # Win32API is required in self.guess
    getTickCount = Win32API.new("kernel32", "GetTickCount", nil, 'L')
    ((getTickCount.call()).to_f / 1000).to_f
  end
  def find_uptime_ruby_unix_osx
    # This is faster than "who" and could work on BSD also. 
    (Time.now.to_f - Time.at(`sysctl -b kern.boottime 2>/dev/null`.unpack('L').first).to_f).to_f
  end
  
  # This should work for most unix flavours.
  def find_uptime_ruby_unix
    # who is sloooooow. Use File.read('/proc/uptime')
    (Time.now.to_i - Time.parse(`who -b 2>/dev/null`).to_f)
  end
  alias_method :find_uptime_java_unix_osx, :find_uptime_ruby_unix
  
  # Determine the values for vm, os, impl, and arch when running on Java. 
  def guess_java
    vm, os, impl, arch = :java, :unknown, :unknown, :unknown
    require 'java'
    include_class java.lang.System unless defined?(System)
    
    osname = System.getProperty("os.name")
    IMPLEMENTATIONS.each do |r, o, i|
      next unless osname =~ r
      os, impl = [o, i]
      break
    end
    
    osarch = System.getProperty("os.arch")
    ARCHITECTURES.each do |r, a|
      next unless osarch =~ r
      arch = a
      break
    end
    [vm, os, impl, arch]
  end
  
  # Returns the local IP address based on the hostname. 
  # According to coderrr (see comments on blog link above), this implementation
  # doesn't guarantee that it will return the address for the interface external
  # traffic goes through. It's also possible the hostname isn't resolvable to the
  # local IP.  
  #
  # NOTE: This code predates the current ip_address_internal. It was just as well
  # but the other code is cleaner. I'm keeping this old version here for now.
  def ip_address_internal_alt
    ipaddr = :unknown
    begin
      saddr = Socket.getaddrinfo(  Socket.gethostname, nil, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME)
      ipaddr = saddr.select{|type| type[0] == 'AF_INET' }[0][3]
    rescue => ex
    end
    ipaddr
  end
end


if $0 == __FILE__
  puts SysInfo.new.to_yaml
end