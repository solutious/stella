


module Stella 
  class CLI
    class Watch < Stella::CLI::Base
      
      def initialize(adapter)
        super(adapter)
         
        if adapter == 'pcap'
          
          if can_pcap?
            require 'stella/adapter/pcap'
            @adapter = Stella::Adapter::Pcap.new
          else
            # if can_pcap? returned false, but pcap was requested then we'll
            # call check_pcap to raise the reason why it didn't load. 
            check_pcap
            exit 1
          end
        elsif adapter == 'proxy'
          @adapter = Stella::Adapter::Proxy.new
        else
          raise UnknownValue.new(adapter)
        end
        
        
      end
      
      def run
        
        @driver = Stella::Command::Watch.new(@adapter)
        @driver.format = @stella_options.format
        @driver.quiet = @stella_options.quiet
        @driver.verbose = @stella_options.verbose
        @driver.force = @stella_options.force
        
        process_arguments(@arguments)
        
        @driver.run

      end
      
      
      # Returns true is pcap is available 
      def can_pcap?
        begin
          check_pcap
        rescue
          return false
        end
        return true
      end

      # The Pcap gauntlet. A number of conditions must be met to run the Pcap recorder:
      # - The OS must be a form of Unix
      # - Cannot be running via JRuby or Java
      # - The user must be root (or running through sudo)
      # - The Ruby-Pcap library must be installed for the version of Ruby being used. 
      def check_pcap
        raise MissingDependency.new('pcap', :error_sysinfo_notunix) unless Stella::SYSINFO.os === :unix # pcap not available on windows or java
        raise MissingDependency.new('pcap', :error_sysinfo_notroot) unless ENV['USER'] === 'root' # Must run as root or sudo
        begin 
          require 'pcap'
        rescue Exception, LoadError => ex
          raise MissingDependency.new('pcap', :error_watch_norubypcap)
        end
        false
      end

      
      def process_arguments(arguments, display=false)
        opts = OptionParser.new
        
        opts.banner = "Usage: #{File.basename($0)} [global options] watch [command options] [http|dns]"
        opts.on("#{$/}Example: #{File.basename($0)} -v #{@adapter} http#{$/}")
        opts.on('-h', '--help', "Display this message") do
          Stella::LOGGER.info opts
          exit 0
        end
        
        
        if @adapter == 'pcap' 
          opts.on('-i=S', '--interface=S', String, "Network device. eri0, en1, etc. (with --usepcap only)") do |v| @driver.interface = v end
          opts.on('-m=N', '--maxpacks=N', Integer, "Maximum number of packets to sniff (with --usepcap only)") do |v| @driver.maxpacks = v end
          opts.on('-R=S', '--protocol=S', String, "Communication protocol to sniff. udp or tcp (with --usepcap only)") do |v| @driver.protocol = v end
        end
        
        opts.on('-p=N', '--port=N', Integer, "With --useproxy this is the Proxy port. With --usecap this is the TCP port to filter. ") do |v| @driver.port = v end
        #opts.on('-c', '--cookies' , "Only display cookies") do |v| v end
        #opts.on('-f=S', '--filter=S', String, "Filter out requests which do not contain this string") do |v| v end
        #opts.on('-d=S', '--domain=S', String, "Only display requests to the given domain") do |v| v end
        #opts.on('-r=S', '--record=S', String, "Record requests to file with an optional filename") do |v| v || true end
        #opts.on('-F=S', '--format=S', "Format of recorded file. One of: simple (for Siege), session (for Httperf)") do |v| v end
        
      end
      
    end
    
    @@commands['pcap'] = Stella::CLI::Watch
    @@commands['proxy'] = Stella::CLI::Watch
  end
end


__END__

# pageload?
#
# Used while writing the session log file. Returns true when we
# suspect a new page has loaded. Otherwise the resource is considered 
# to be a dependency. 
def pageload?(now, think_time, host, referer, content_type)
  time_difference = (now.to_i - @think_time.to_i)
  time_passed = (@think_time == 0 || time_difference > 4) 
  non_html = (content_type !~ /text\/html/i) if content_type
  #puts "POOO: #{content_type} #{referer}"
  
  case [time_passed, non_html]
  when [true,false]
    return true
  when [true,true]
    return false
  when [true,nil]
    return true
  when [false,false]
    return false
  else
    return false
  end
end
