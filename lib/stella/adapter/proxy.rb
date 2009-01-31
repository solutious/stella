
require 'webrick/httpproxy'
require 'observer'


module Stella
  module Adapter

    # Starts up an HTTP proxy using WEBrick to record HTTP events. This is used
    # when PcapRecorder is not available. 
    class Proxy
      include Observable
      
      attr_accessor :port
      
      def initialize(options={})
        @port = options[:port]
      end
      require 'pp'
      def run

        @server = WEBrick::HTTPProxyServer.new(
            :Port => @port || 3114,
            :AccessLog => [],
            :ProxyContentHandler => Proc.new do |req,res|
              
                begin
                  res_obj = Stella::Data::HTTPResponse.new(res.to_s)
                  res_obj.time = Time.now
                  
                  req_obj = Stella::Data::HTTPRequest.new(req.to_s)
                  req_obj.time = Time.now
                  req_obj.client_ip = '0.0.0.0'
                  req_obj.server_ip = '0.0.0.0'

                  req_obj.response = res_obj

                  changed
                  notify_observers(:http_request, req_obj)
                  
                rescue SystemExit => ex
                  after
                  
                rescue Exception => ex
                  # There are miscellaneous errors (mostly to do with
                  # incorrect content-length) that we don't care about. 
                  Stella::LOGGER.error(ex.message)
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
