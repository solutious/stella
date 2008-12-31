# http://90kts.com/blog/2008/httpwatch-a-free-alternative-using-ruby/
# http://90kts.com/blog/2008/just-another-framework-for-developing-watir-test-cases/
require 'rubygems' 
require 'webrick/httpproxy'

begin
 #require 'Win32/Console/ANSI' if RUBY_PLATFORM =~ /win32/
 require 'highline/import'    if RUBY_PLATFORM =~ /darwin/
rescue LoadError
 raise 'You must gem install win32console to use color on Windows'
end





module Stella 
  class CLI
    class Spy < Stella::CLI::Base
      @proxy_port    = ARGV[0] || 9090
      @search_body   = ''

 
      
      def run
        # Optional flags
         @print_headers  = false 
         @print_body     = true  
         @pretty_colours = true
         
        puts Stella::SYSINFO.platform
        
        server = WEBrick::HTTPProxyServer.new(
            :Port => 9090,
            :AccessLog => [], # suppress standard messages

            :ProxyContentHandler => Proc.new do |req,res|
                puts "-"*75
                puts ">>> #{req.request_line.chomp}\n"
                req.header.keys.each do |k|
                    puts "#{k.capitalize}: #{req.header[k]}" if @print_headers
                end

                puts "<<<" if @print_headers
                puts res.status_line if @print_headers
                res.header.keys.each do |k|
                    puts "#{k.capitalize}: #{res.header[k]}" if @print_headers
                end
                unless res.body.nil? or !@print_body then
                    body = res.body.split("\n")
                    line_no = 1
                    body.each do |line|
                      if line.to_s =~ /poop/ then
                        puts "\n<<< #{line_no} #{line.gsub(/poop/, 
                          "\e[32mpoop\e[0m")}"
                        #puts "\n<<< #{line_no} #{line}" unless @pretty_colours
                      end
                      line_no += 1
                    end
                end
            end
        )
        trap("INT") { server.shutdown }
        server.start
        
      end
      
    end
    
    @@commands['spy'] = Stella::CLI::Spy
  end
end

