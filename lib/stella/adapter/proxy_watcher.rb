
require 'webrick/httpproxy'
require 'observer'

#begin
# #require 'Win32/Console/ANSI' if RUBY_PLATFORM =~ /win32/
# require 'highline/import'    if RUBY_PLATFORM =~ /darwin/
#rescue LoadError
# raise 'You must gem install win32console to use color on Windows'
#end


module Stella
  module Adapter
    
    # Stella::Adapter::ProxyWatcher
    #
    # Starts up an HTTP proxy using WEBrick to record HTTP events. This is used
    # when PcapRecorder is not available. 
    class ProxyWatcher
      include Observable
      
      def initialize(options={})

      end
      
      
      def run
        @search_body   = ''
        # Optional flags
         @print_headers  = false 
         @print_body     = true  
         @pretty_colours = true
         
        
        @server = WEBrick::HTTPProxyServer.new(
            :Port => 3114,
            :AccessLog => [],
            :ProxyContentHandler => Proc.new do |req,res|
                
                begin
                  changed
                  notify_observers('http', req, res)
                rescue => ex
                  # There are miscellaneous errors (mostly to do with
                  # incorrect content-length) that we don't care about. 
                end
                
                #Stella::LOGGER.info(req.class)
                #puts "-"*75
                #puts ">>> #{req.request_line.chomp}\n"
                #req.header.keys.each do |k|
                #    puts "#{k.capitalize}: #{req.header[k]}" if @print_headers
                #end
                #
                #puts "<<<" if @print_headers
                #puts res.status_line if @print_headers
                #res.header.keys.each do |k|
                #    puts "#{k.capitalize}: #{res.header[k]}" if @print_headers
                #end
                #unless res.body.nil? or !@print_body then
                #    body = res.body.split("\n")
                #    line_no = 1
                #    body.each do |line|
                #      if line.to_s =~ /poop/ then
                #        puts "\n<<< #{line_no} #{line.gsub(/poop/, 
                #          "\e[32mpoop\e[0m")}"
                #        #puts "\n<<< #{line_no} #{line}" unless @pretty_colours
                #      end
                #      line_no += 1
                #    end
                #end
            end
        )
        
        @server.start
      end
      
      def after
        delete_observers
        @server.shutdown
      end
      
    end
  end
end
