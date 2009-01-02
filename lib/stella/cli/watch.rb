

module Stella 
  class CLI
    class Watch < Stella::CLI::Base


      def run
        @options = process_arguments(@arguments)
        
        if can_pcap?(@options[:usepcap]) 
          require 'stella/adapter/pcap_watcher'
          @watcher = Stella::Adapter::PcapWatcher.new(@options)
        else
          require 'stella/adapter/proxy_watcher'
          @watcher = Stella::Adapter::ProxyWatcher.new(@options)
          
          if @options[:usepcap]
            check_pcap
            exit 0
          end
        end
        
        
        
        @watcher.run
      end
      
      # can_pcap?
      #
      # Returns true is pcap is available 
      def can_pcap?(usepcap=false)
        return false unless usepcap
        begin
          check_pcap
        rescue
          return false
        end
        return true
      end
      
      # check_pcap
      #
      # The Pcap gauntlet. A number of conditions must be met to run the Pcap recorder:
      # - The watch command must be called with -p
      # - The OS must be a form of Unix
      # - Cannot be running via JRuby or Java
      # - The user must be root (or running through sudo)
      # - The Ruby-Pcap library must be installed.
      def check_pcap(usepcap=false)
        raise MissingDependency.new('pcap', :error_sysinfo_notunix) unless Stella::SYSINFO.os === :unix # pcap not available on windows or java
        raise MissingDependency.new('pcap', :error_sysinfo_notroot) unless ENV['USER'] === 'root' # Must run as root or sudo
        begin 
          require 'pcap'
        rescue => ex
          raise MissingDependency.new('pcap', :errot_watch_norubypcap)
        end
        false
      end
      
      def process_arguments(arguments)
        opts = OptionParser.new
        
        opts.banner = "Usage: #{File.basename($0)} [global options] watch [command options]"
        opts.on('-P', '--usepcap', "Use Pcap to filter TCP packets") do |v| v end
        opts.on('-W', '--useproxy', "Use an HTTP proxy to filter requests (default)") do |v| v end
          
        opts.on("#{$/}Pcap-specific options")
        opts.on('-s=S', '--service=S', String, "Filter either http (default) or dns (with --usepcap only)") do |v| v end
        opts.on('-i=S', '--interface=S', String, "Network interface. eri0, en1, etc. (with --usepcap only)") do |v| v end
        
        
        opts.on("#{$/}Common options")
        opts.on('-p=N', '--port=N', Integer, "With --useproxy this is the Proxy port. With --usecap this is the TCP port to filter. ") do |v| v end
        opts.on('-f=S', '--filter=S', "Filter out requests which do not contain this string") do |v| v end
        
        options = opts.getopts(arguments)  
        options = options.keys.inject({}) do |hash, key|
           hash[key.to_sym] = options[key]
           hash
        end
        options
      end
      
    end
    
    @@commands['watch'] = Stella::CLI::Watch
  end
end

