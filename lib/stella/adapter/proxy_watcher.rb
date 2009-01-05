
require 'webrick/httpproxy'
require 'observer'


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
                
            end
        )
        
        # We need to trap this INT to kill WEBrick. Unlike with Pcap, 
        # rescuing Interrupt doesn't work. 
        
        trap('INT') do
		      after
	      end
	      
        @server.start
	      after
	      
      rescue Interrupt  
	      after
      rescue => ex  
	      after
      end
      
      def after
        delete_observers
        @server.shutdown
      end
      
    end
  end
end
