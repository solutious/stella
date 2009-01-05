

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
          
          # if can_pcap? returned false, but pcap was requested then we'll
          # call check_pcap to raise the reason why it didn't load. 
          if @options[:usepcap]
            check_pcap
            exit 0
          end
        end
        
        # We use an observer model so the watcher class will notify us
        # when they have new data. They call the update method below. 
        @watcher.add_observer(self)
        
        if @options[:record]
          
          @record_filepath = generate_record_filepath 
        
          if File.exists?(@record_filepath) 
            Stella::LOGGER.error("#{@record_filepath} exists")
            if @stella_options.force
              Stella::LOGGER.error("But I'll overwrite it and continue because you forced me too!")
            else
              exit 1
            end
          end
          
        end
      
        @watcher.run
      
      end
      

      
      # update
      #
      # This method is called from the watcher class when data is updated. 
      # +service+ is one of: domain, http
      # +req+ is a WEBrick::HTTPRequest object when service is http. Otherwise a hash. 
      # +resp+ is a WEBrick::HTTPResponse object when service is http. Otherwise it's nil.  
      def update(service, req, resp=nil)
        
        if @options[:record] && !@file_created_already
          if File.exists?(@record_filepath) 
            if @stella_options.force
              @record_file = FileUtil.create_file(@record_filepath, 'w', ".", :force)
            else
              exit 1
            end
          else
            @record_file = FileUtil.create_file(@record_filepath, 'w', ".")
          end
          Stella::LOGGER.info("Writing to #{@record_filepath}")
          @file_created_already = true
        end
        
        if (service == "http")
          update_http(req, resp)
        elsif (service == "domain")
          update_domain(req)
        end
      end
      
      def update_domain(req)
        
        return if @options[:filter] && !(req[:target].to_s =~ /#{@options[:filter]}/i)
        return if @options[:host] && !(req[:target].to_s =~ /(www.)?#{@options[:host]}/i)
        
        if @stella_options.verbose > 0
          Stella::LOGGER.info('-'*50)
          Stella::LOGGER.info(req[:resp_packet].inspect, '')
        else
          Stella::LOGGER.info("#{req[:request_time].strftime("%Y-%m-%d@%H:%M:%S")}: #{req[:target]} -> #{req[:address].join(', ')}")
        end
      end
      
      def update_http(req, resp)
        
        return if req.request_time.nil? # Incomplete packets return unpredictable results
        return if @options[:filter] && !(req.request_uri.to_s =~ /#{@options[:filter]}/i)
        return if @options[:host] && !(req.host.to_s =~ /(www.)?#{@options[:host]}/i)
          
        begin
          if (@options[:record])
            if (@options[:format] == 'session')
              
            else
              @record_file.puts req.request_uri
            end
            
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
            Stella::LOGGER.info("#{req.request_time.strftime("%Y-%m-%d@%H:%M:%S")}: #{req.request_uri}")
          end
        rescue => ex
          # Is it just me or is WEBrick kind of annoying. In any case, it can raise
          # WEBrick::HTTPStatus::LengthRequired exceptions that we don't care about
          Stella::LOGGER.error(ex)
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
      
      def generate_record_filepath
        filepath = nil
        
        if (@options[:record].is_a? String)
          filepath = File.expand_path(@options[:record])
        else
          now = DateTime.now
          daystr = "#{now.year}-#{now.mon.to_s.rjust(2,'0')}-#{now.mday.to_s.rjust(2,'0')}"
          dirpath = File.join(@working_directory, 'stories', daystr)

          FileUtil.create_dir(dirpath, ".")
          filepath = File.join(dirpath, 'story')
          testnum = 1.to_s.rjust(2,'0')
          testnum.succ! while(File.exists? "#{filepath}-#{testnum}.txt")
          filepath = "#{filepath}-#{testnum}.txt"
        end
          
        return filepath
      end
      
      def after
        # Close Pcap / Shutdown Proxy
        @watcher.after
        
        # We don't need to close or delete a file that wasn't created
        return unless @record_file
        
        # And we don't want to delete a file that we're overwriting but may
        # not have actually written anything to yet. IOW, original file will
        # remain intact if we haven't written anything to it yet. 
        @record_file.close if @forced_overwrite
        
        # Delete an empty file, otherwise close it
        @record_file.stat.size == 0 ? File.unlink(@record_file.path) : @record_file.close
      end
      
      def process_arguments(arguments, display=false)
        opts = OptionParser.new
        
        opts.banner = "Usage: #{File.basename($0)} [global options] watch [command options] [http|dns]"
        opts.on("#{$/}Example: #{File.basename($0)} -v watch -p dns#{$/}")
        opts.on('-h', '--help', "Display this message") do
          Stella::LOGGER.info opts
          exit 0
        end
        
        opts.on("#{$/}Operating mode")
        opts.on('-W', '--useproxy', "Use an HTTP proxy to filter requests (default)") do |v| v end
        opts.on('-P', '--usepcap', "Use Pcap to filter TCP packets") do |v| v end
          
        opts.on("#{$/}Pcap-specific options")
        opts.on('-i=S', '--interface=S', String, "Network device. eri0, en1, etc. (with --usepcap only)") do |v| v end
        opts.on('-m=N', '--maxpacks=N', Integer, "Maximum number of packets to sniff (with --usepcap only)") do |v| v end
        opts.on('', '--protocol=S', String, "Communication protocol to sniff. udp or tcp (with --usepcap only)") do |v| v end
        
        opts.on("#{$/}Common options")
        opts.on('-p=N', '--port=N', Integer, "With --useproxy this is the Proxy port. With --usecap this is the TCP port to filter. ") do |v| v end
        opts.on('-f=S', '--filter=S', "Filter out requests which do not contain this string") do |v| v end
        opts.on('-d=S', '--domain=S', "Only display requests to the given domain") do |v| v end
        opts.on('-r[S]', '--record=[S]', "Record requests to file with an optional filename") do |v| v || true end
        opts.on('-F=S', '--format=S', "Format of recorded file. One of: simple (for Siege), session (for Httperf)") do |v| v end
            
        options = opts.getopts(@arguments)  
        options = options.keys.inject({}) do |hash, key|
           hash[key.to_sym] = options[key]
           hash
        end
                
        # "interface" is more clear on the command line but we use "device" internally
        options[:device] = options.delete(:interface) if options[:interface]
        options[:service] = arguments.shift unless arguments.empty?
        
        options
      end
      
    end
    
    @@commands['watch'] = Stella::CLI::Watch
  end
end

