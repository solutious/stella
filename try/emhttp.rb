# ruby -Ilib try/emhttp.rb http://www.blamestella.com/
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


__END__ 

class EventMachine::HttpRequest
  alias_method :original_send_request, :send_request
  def send_request(&blk)
    $s = Time.now.to_f
    ret = original_send_request(&blk)
    
    ret
  end
end


class EventMachine::HttpClient
  alias_method :original_connection_completed, :connection_completed
  def connection_completed
    ret = original_connection_completed
    e = Time.now.to_f
    p [:connect2, e-$s]
    ret
  end
end