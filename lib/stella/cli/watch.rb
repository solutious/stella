
# TODO: Record cookies. 

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
          Stella::LOGGER.info("Writing to #{@record_filepath}")
        
          if File.exists?(@record_filepath) 
            Stella::LOGGER.error("#{@record_filepath} exists")
            if @stella_options.force
              Stella::LOGGER.error("But I'll overwrite it and continue because you forced me too!")
            else
              exit 1
            end
          end
          
        end
        
        Stella::LOGGER.info("Filter: #{@options[:filter]}") if @options[:filter]
        Stella::LOGGER.info("Domain: #{@options[:domain]}") if @options[:domain]
        
        # Turn wildcards into regular expressions
        @options[:filter].gsub!('*', '.*') if @options[:filter] 
        @options[:domain].gsub!('*', '.*') if @options[:domain]
        
        # Used to calculated user think times for session output
        @think_time = 0
        
        @watcher.run
        
      end
      

      
      # update
      #
      # This method is called from the watcher class when data is updated. 
      # +service+ is one of: domain, http_request, http_response
      # +data+ is a string of TCP packet data. The format depends on the value of +service+.
      def update(service, data_object)
        
        begin
          if @options[:record] && !@file_created_already
        
            if File.exists?(@record_filepath) 
              if @stella_options.force
  		          @record_file = FileUtil.create_file(@record_filepath, 'w', '.', :force)
              else
                exit 1
              end
            else
  		        @record_file = FileUtil.create_file(@record_filepath, 'w', '.')
            end
	        
  	        raise StellaError.new("Cannot open: #{@record_filepath}") unless @record_file

            @file_created_already = true
          end
        rescue => ex
          raise StellaError.new("Error creating file: #{ex.message}")
        end
        
        return if @options[:filter] && !(data.to_s =~ /#{@options[:filter]}/i)
        return if @options[:domain] && !(data.to_s =~ /(www.)?#{@options[:domain]}/i)
        
        if @stella_options.format && data_object.respond_to?("to_#{@stella_options.format}")
          Stella::LOGGER.info(data_object.send("to_#{@stella_options.format}"))
        else 
          if @stella_options.verbose > 1
            Stella::LOGGER.info(data_object.inspect, '', '')
          
          elsif @stella_options.verbose > 0 
            Stella::LOGGER.info(data_object.to_s)
            Stella::LOGGER.info(data_object.body) if data_object.body
          else
            Stella::LOGGER.info(data_object.to_s)
          end
        end
                
      rescue Exception => ex
        Stella::LOGGER.error(ex)
        exit 1
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
        opts.on('-f=S', '--filter=S', String, "Filter out requests which do not contain this string") do |v| v end
        opts.on('-d=S', '--domain=S', String, "Only display requests to the given domain") do |v| v end
        opts.on('-r=S', '--record=S', String, "Record requests to file with an optional filename") do |v| v || true end
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


def update_http(req, resp)
  
  return if req.request_time.nil? # Incomplete packets return unpredictable results
  return if @options[:filter] && req.request_uri.to_s !~ /#{@options[:filter]}/i
  
  if @options[:domain] 
    # expand the wildcard
    domain = @options[:domain].gsub('*', '.*')
    return unless req.host.to_s =~ /(www.)?#{domain}/i
  end
  
  begin
    if (@options[:record])
      @sess_number ||= 0
      
      if (@options[:format] == 'session')
        now = Time.now
        
        if pageload?(now, @think_time, req.request_uri.host, req.header['referer'][0], resp.content_type)
          delay = (@think_time == 0) ? 0 : now.to_f - @think_time.to_f
          
          if delay == 0 || delay >= 10 
            @sess_number += 1
            @record_file.puts('', "# SESSION NUMBER #{@sess_number}")
          end
          line = req.path 
          line << "?" << req.query_string if req.query_string 
          line << sprintf(" think=%.2f", delay)
          @record_file.puts line
          @think_time = now
        else
          delay = sprintf("%.2f", now.to_f - @think_time.to_f)
          line = "\t#{req.path}" 
          line << "?" << req.query_string if req.query_string 
          @record_file.puts line
        end
        
      else
        @record_file.puts req.request_uri
      end
      
      @record_file.flush
    end
  
    if @stella_options.verbose == 1
      Stella::LOGGER.info(req.to_s) # with an extra line between request headers
      Stella::LOGGER.info("HTTP/#{resp.http_version} #{resp.status}", '') if resp
      
    elsif @stella_options.verbose == 2
      Stella::LOGGER.info(req.to_s, '') # with an extra line between request headers
      
      if (resp)
        # Recreate the HTTP/1.1 200 line and then print the headers.
        # WEBrick returns a hash so we need to format it. 
        Stella::LOGGER.info("HTTP/#{resp.http_version} #{resp.status}")
        resp.header.each_pair do |n,v|
          Stella::LOGGER.info("#{n.capitalize}: #{v}")
        end
      end
      
    elsif @stella_options.verbose > 2
      Stella::LOGGER.info('-'*50)
      Stella::LOGGER.info(req.request_uri)
      Stella::LOGGER.info(req.inspect)
      
      if resp
        # We don't want to print binary data (images, gzip, etc...). So we only print 
        # the full response when it's text and not encoded. Unless the body is empty
        # (which happens for HEAD requests and 3XX responses)
        if (resp.content_type && resp.content_type.match(/text/) && resp.header['content-encoding'] != 'gzip') || resp.body.nil?
          Stella::LOGGER.info(resp.inspect) 
        else
          # Recreate the HTTP/1.1 200 line and then print the headers.
          # WEBrick returns a hash so we need to format it. 
          Stella::LOGGER.info("HTTP/#{resp.http_version} #{resp.status}")
          resp.header.each_pair do |n,v|
            Stella::LOGGER.info("#{n.capitalize}: #{v}")
          end
          Stella::LOGGER.info("[binary content removed]", '') 
        end
      end
      Stella::LOGGER.info("#{$/}")
    else
      line = req.request_time.strftime("%Y-%m-%d@%H:%M:%S: ")
      line << " #{resp.status}" if resp
      line << " #{req.request_uri}"
      Stella::LOGGER.info(line)
    end
  rescue => ex
    # Is it just me or is WEBrick kind of annoying. In any case, it can raise
    # WEBrick::HTTPStatus::LengthRequired exceptions that we don't care about
    Stella::LOGGER.error(ex)
  end
end