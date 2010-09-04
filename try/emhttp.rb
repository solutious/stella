# ruby -Ilib try/emhttp.rb
require 'stella'
require 'eventmachine'
require 'em-http'
require 'fiber'
require 'benelux'
require 'pp'

urls = ARGV
if urls.size < 1
  puts "Usage: #{$0} <url> <url> <...>"
  exit
end

pending = urls.size

Benelux.add_timer EventMachine::HttpClient, :connection_completed, :socket_connect

EM.run do
  urls.each do |url|
    http = EM::HttpRequest.new(url).get
    http.callback {
      puts "#{url}\n#{http.response_header.status} - #{http.response.length} bytes\n"
      puts http.response.class

      pending -= 1
      EM.stop if pending < 1
    }
    http.errback {
      puts "#{url}\n" + http.error

      pending -= 1
      EM.stop if pending < 1
    }
  end
end

pp Benelux.current_track.timeline.stats.group(:socket_connect).merge
