

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
        
        # We use an observer model so the watcher class will notify us
        # when they have new data. They call the update method below. 
        @watcher.add_observer(self)
        
        Signal.trap('INT') do
          after
          @killer.run     # See CLI::Base
        end
        
        
        @record_file = create_record_file if @options[:record]
        
        @watcher.run
      
      end
      
      def create_record_file
        file = (@options[:record].is_a? String) ? @options[:record] : 'story'
        
        now = DateTime.now
        daystr = "#{now.year}-#{now.mon.to_s.rjust(2,'0')}-#{now.mday.to_s.rjust(2,'0')}"
        dirpath = File.join(@working_directory, 'stories', daystr)
        
        FileUtil.create_dir(dirpath, ".")
        filepath = File.join(dirpath, file)
        testnum = 1.to_s.rjust(2,'0')
        testnum.succ! while(File.exists? "#{filepath}-#{testnum}.txt")
        filepath = "#{filepath}-#{testnum}.txt"
        Stella::LOGGER.info("Writing to #{filepath}")
        
        FileUtil.create_file(filepath, 'w', ".")
      end
      
      def after
        @watcher.after  # Close Pcap / Shutdown Proxy
        return unless @record_file
        @record_file.stat.size == 0 ? File.unlink(@record_file.path) : @record_file.close
      end
      
      # update
      #
      # This method is called from the watcher class when data is updated. 
      # +service+ is one of: domain, http
      # +req+ is a WEBrick::HTTPRequest object when service is http. Otherwise a hash. 
      # +resp+ is a WEBrick::HTTPResponse object when service is http. Otherwise it's nil.  
      def update(service, req, resp=nil)
        
        return if @options[:filter] && !(req.request_uri.to_s =~ /#{@options[:filter]}/i)
        return if @options[:host] && !(req.host.to_s =~ /(www.)?#{@options[:host]}/i)
          
        begin
          if (@options[:record])
            @record_file.puts req.request_uri
            @record_file.flush
          end
        
          if @stella_options.verbose == 1
            Stella::LOGGER.info(req.to_s, '') # with an extra line between request headers
          elsif @stella_options.verbose == 2
            Stella::LOGGER.info(req.to_s, '') 
            Stella::LOGGER.info(resp.to_s)
          elsif @stella_options.verbose > 2
            Stella::LOGGER.info('-'*50)
            Stella::LOGGER.info(req.request_uri)
            Stella::LOGGER.info(req.inspect)
            Stella::LOGGER.info(resp.inspect)
          else
            Stella::LOGGER.info("#{req.request_time.strftime("%Y-%m-%d@%H:%M:%S")}: #{service}://#{req.host}:#{req.port}#{req.path}")
          end
        rescue => ex
          # Is it just me or is WEBrick kind of annoying. In any case, it can raise
          # WEBrick::HTTPStatus::LengthRequired exceptions that we don't about
        end
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
        opts.on('-i=S', '--interface=S', String, "Network device. eri0, en1, etc. (with --usepcap only)") do |v| v end
        
        opts.on("#{$/}Common options")
        opts.on('-p=N', '--port=N', Integer, "With --useproxy this is the Proxy port. With --usecap this is the TCP port to filter. ") do |v| v end
        opts.on('-f=S', '--filter=S', "Filter out requests which do not contain this string") do |v| v end
        opts.on('-h=S', '--host=S', "Only display requests to the given hostname") do |v| v end
        opts.on('-r=[S]', '--record=[S]', "Record requests to file (saved to stella/story001.txt unless specified)") do |v| v || true end
          
        options = opts.getopts(arguments)  
        options = options.keys.inject({}) do |hash, key|
           hash[key.to_sym] = options[key]
           hash
        end
        
        # "interface" is more clear on the command line but we use "device" internally
        options[:device] = options.delete(:interface) if options[:interface]
        
        options
      end
      
    end
    
    @@commands['watch'] = Stella::CLI::Watch
  end
end

