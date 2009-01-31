

module Stella::Command
  class Watch < Stella::Command::Base
    
    attr_accessor :adapter
    
      # pcap-only, the network interface name
    attr_accessor :interface
      # pcap-only, maximum number of packets to filter
    attr_accessor :maxpacks
      # pcap-only, network protocol to watch, one of tcp (default) or udp
    attr_accessor :protocol
      # pcap-only, service to watch, one of http (default) or dns
    attr_accessor :service
    
      # Port number. In proxy mode, this sets the port number to run on. 
    attr_accessor :port
      
      # Boolean value that determines whether to save the output to disk. 
    attr_accessor :record
    attr_accessor :filter
    attr_accessor :domain
    
    def initialize(adapter=nil)
      @adapter = adapter if adapter 
    end
    
    def run

      # We use an observer model so the watcher class will notify us
      # when they have new data. They call the update method below. 
      @adapter.add_observer(self)
      
      if @record
        
        @record_filepath = generate_record_filepath 
        Stella::LOGGER.info("Writing to #{@record_filepath}")
      
        if File.exists?(@record_filepath) 
          Stella::LOGGER.error("#{@record_filepath} exists")
          if @force
            Stella::LOGGER.error("But I'll overwrite it and continue because you forced me too!")
          else
            exit 1
          end
        end
        
      end
      
      Stella::LOGGER.info("Filter: #{@filter}") if @filter
      Stella::LOGGER.info("Domain: #{@domain}") if @domain
      
      # Turn wildcards into regular expressions
      @filter.gsub!('*', '.*') if @filter 
      @domain.gsub!('*', '.*') if @domain
      
      # Used to calculated user think times for session output
      @think_time = 0
      
      @adapter.run
      
    end
    

    
    # update
    #
    # This method is called from the watcher class when data is updated. 
    # +service+ is one of: domain, http_request, http_response
    # +data+ is a string of TCP packet data. The format depends on the value of +service+.
    def update(service, data_object)
      
      begin
        if @record && !@file_created_already
      
          if File.exists?(@record_filepath) 
            if @force
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
      
      
      #if @cookies
      #  Stella::LOGGER.info(data_object.to_s) 
      #  Stella::LOGGER.info(data_object.cookies.join("#{$/} -> "))
      #  
      #  if data_object.has_response?
      #    Stella::LOGGER.info(data_object.response.to_s)
      #    Stella::LOGGER.info(" -> " << data_object.response.cookies.join("#{$/} -> "))          
      #  end
      #  
      if @format && data_object.respond_to?("to_#{@format}")
        Stella::LOGGER.info(data_object.send("to_#{@format}"))
        
        if data_object.has_response?
          Stella::LOGGER.info(data_object.response.send("to_#{@format}"))
        end
        
      else 
        if @verbose > 1
          Stella::LOGGER.info(data_object.inspect, '')
          
          if data_object.has_response?
            Stella::LOGGER.info(data_object.response.inspect, '', '')
          end
          
        elsif @verbose == 1
          Stella::LOGGER.info(data_object.to_s)
          Stella::LOGGER.info(data_object.body) if data_object.has_body?
          
          if data_object.has_response?
            Stella::LOGGER.info(data_object.response.to_s) 
            Stella::LOGGER.info(data_object.response.body) if data_object.response.has_body?
          end
          
        else
          Stella::LOGGER.info(data_object.to_s)
          Stella::LOGGER.info(data_object.response.to_s) if data_object.has_response?
          
        end
      end
              
    rescue Exception => ex
      Stella::LOGGER.error(ex)
      #exit 1
    end
    
    
    
    
    def generate_record_filepath
      filepath = nil
      
      if (@record.is_a? String)
        filepath = File.expand_path(@record)
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
      @adapter.after
      
      # We don't need to close or delete a file that wasn't created
      return unless @record_file
      
      # And we don't want to delete a file that we're overwriting but may
      # not have actually written anything to yet. IOW, original file will
      # remain intact if we haven't written anything to it yet. 
      @record_file.close if @forced_overwrite
      
      # Delete an empty file, otherwise close it
      @record_file.stat.size == 0 ? File.unlink(@record_file.path) : @record_file.close
    end
    
    
  end  
end
