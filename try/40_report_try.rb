require 'stella'

# 
# require 'socket'
# 
# class TCPSocket
#   
#   def write(*args)
#     STDOUT.puts caller
#     STDOUT.puts [args].inspect
#     super
#   end
#   
# end
# 


Stella.debug = true

## Stella::Report is aware of all available modes
Stella::Report.plugins
#=> {:errors=>Stella::Report::Errors, :statuses=>Stella::Report::Statuses, :headers=>Stella::Report::Headers, :content=>Stella::Report::Content, :metrics=>Stella::Report::Metrics}

## Headers has a mode
Stella::Report::Headers.plugin
#=> :headers


## Can process a timline
thread = Thread.new do
  log = Stella::Engine
  Benelux.timeline.add_message(:kind => :http_log)
end
thread.join
timeline = Benelux.merge_tracks
report = Stella::Report.new timeline
report.process
report.processed?
##=> true


#  uri = URI.parse ARGV.first
#  @plan = Stella::Testplan.new uri
#  @run = Stella::Testrun.new @plan, :checkup, :repetitions => 1
#  @report = Stella::Engine::Checkup.run @run; nil
#  run = Stella::Testrun.from_yaml @run.to_yaml
#  puts @run.to_yaml
#  puts '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
#  puts run.to_yaml
#  puts @run.errors?, run.errors?, run.report.errors?, run.report.statuses.nonsuccessful

# $ stella checkup http://solutious.com/
# ......
# 
# Metrics
#  socket connect:     10ms
#    send request:     20ms
#      first byte:     30ms
#       last byte:     10ms
#   response time:     70ms
# 
# Content
#   page size:       6237kb      
#
# Headers
#   HTTP/1.1 200 OK
#   Server: nginx/0.7.61
#   Date: Mon, 19 Jul 2010 17:05:23 GMT
#   Content-Type: text/html
#   Content-Length: 6237
#   Last-Modified: Sat, 19 Jun 2010 20:52:57 GMT
#   Connection: keep-alive
#   Expires: Tue, 20 Jul 2010 17:05:23 GMT
#   Cache-Control: max-age=86400
#   Accept-Ranges: bytes
#
# DNS
#   solutious.com.		1800	IN	A	207.97.227.245
#   
# Host
#   solutious.com has address 207.97.227.245
#   solutious.com mail is handled by 70 ASPMX5.GOOGLEMAIL.com.
#   solutious.com mail is handled by 10 aspmx.l.google.com.
#   solutious.com mail is handled by 20 ALT1.aspmx.l.google.com.
#   solutious.com mail is handled by 30 ALT2.aspmx.l.google.com.
#   solutious.com mail is handled by 40 ASPMX2.GOOGLEMAIL.com.
#   solutious.com mail is handled by 50 ASPMX3.GOOGLEMAIL.com.
#   solutious.com mail is handled by 60 ASPMX4.GOOGLEMAIL.com.
#
# Traceroute
#   traceroute to solutious.com (207.97.227.245), 64 hops max, 52 byte packets
#    1  10.0.1.1 (10.0.1.1)  2.675 ms  1.349 ms  1.302 ms
#    2  10.252.128.1 (10.252.128.1)  10.980 ms  6.433 ms  8.999 ms
#    3  csw2-vlan202.roemd1.lb.home.nl (213.51.154.1)  9.345 ms  9.704 ms  9.546 ms
#    4  csw1-te-1-3.venlo1.lb.home.nl (213.51.157.159)  10.283 ms  10.799 ms  9.311 ms
#    5  ht-rc0001-cr102-ae1.core.as9143.net (213.51.158.60)  20.401 ms  10.915 ms  14.186 ms
#    6  asd-lc0006-cr101-ae4-0.core.as9143.net (213.51.158.150)  21.662 ms  14.255 ms  12.228 ms
#    7  xe-1-1-0.ams20.ip4.tinet.net (77.67.64.65)  15.084 ms  69.496 ms  15.924 ms
#    8  ge-11-2-8.er1.ams1.nl.above.net (64.125.14.81)  13.785 ms  12.453 ms
#       ge-11-0-8.er1.ams1.nl.above.net (64.125.14.77)  13.796 ms
#    9  ge-3-0-0.mpr1.ams1.nl.above.net (64.125.26.82)  14.467 ms  12.494 ms  18.616 ms
#   10  so-3-0-0.mpr2.ams5.nl.above.net (64.125.28.90)  174.900 ms  16.655 ms  16.108 ms
#   11  so-2-0-0.mpr1.lhr2.uk.above.net (64.125.27.177)  22.962 ms  17.936 ms  21.533 ms
#   12  so-0-1-0.mpr1.dca2.us.above.net (64.125.27.57)  111.692 ms  101.537 ms  99.477 ms
#   13  xe-1-3-0.cr1.dca2.us.above.net (64.125.29.21)  104.827 ms  97.288 ms  97.039 ms
#   14  xe-1-1-0.er1.dca2.us.above.net (64.125.26.174)  96.418 ms  97.254 ms  97.766 ms
#   15  xe-0-1-0.er1.iad10.us.above.net (64.125.31.206)  97.274 ms  97.726 ms  97.298 ms
#   16  209.249.11.37.available.above.net (209.249.11.37)  97.712 ms  96.678 ms  96.586 ms
#   17  vlan905.core5.iad2.rackspace.net (72.4.122.10)  95.289 ms  93.712 ms  95.162 ms
#   18  aggr301a-1-core5.iad2.rackspace.net (72.4.122.121)  95.627 ms  98.100 ms  96.426 ms
#   19  * * * 
#
#    1  10.0.1.1 (10.0.1.1)  4.016 ms  1.309 ms  1.354 ms
#    2  10.252.128.1 (10.252.128.1)  6.601 ms  7.316 ms  7.740 ms
#    3  csw2-vlan202.roemd1.lb.home.nl (213.51.154.1)  7.603 ms  6.178 ms  8.666 ms
#    4  csw1-te-1-3.venlo1.lb.home.nl (213.51.157.159)  8.019 ms  11.461 ms  11.605 ms
#    5  ht-rc0001-cr102-ae1.core.as9143.net (213.51.158.60)  9.469 ms  9.764 ms  9.713 ms
#    6  asd-lc0006-cr101-ae4-0.core.as9143.net (213.51.158.150)  14.732 ms  17.799 ms  15.138 ms
#    7  xe-1-1-0.ams20.ip4.tinet.net (77.67.64.65)  14.819 ms  16.386 ms  13.064 ms
#    8  ge-11-2-8.er1.ams1.nl.above.net (64.125.14.81)  19.631 ms
#       ge-11-0-8.er1.ams1.nl.above.net (64.125.14.77)  13.490 ms  14.538 ms
#    9  ge-3-0-0.mpr1.ams1.nl.above.net (64.125.26.82)  14.018 ms  29.386 ms  17.660 ms
#   10  so-2-1-0.mpr2.ams5.nl.above.net (64.125.31.254)  15.385 ms  12.865 ms  13.080 ms
#   11  xe-3-2-0.mpr1.lhr2.uk.above.net (64.125.31.246)  22.697 ms  20.084 ms  21.045 ms
#   12  so-1-1-0.mpr1.dca2.us.above.net (64.125.31.186)  125.494 ms  111.817 ms  125.886 ms
#   13  xe-0-3-0.cr1.dca2.us.above.net (64.125.29.17)  101.093 ms  106.459 ms  101.872 ms
#   14  xe-0-1-0.er1.dca2.us.above.net (64.125.27.25)  112.132 ms  97.688 ms  99.599 ms
#   15  xe-0-1-0.er1.iad10.us.above.net (64.125.31.206)  104.937 ms  97.064 ms  99.862 ms
#   16  209.249.11.37.available.above.net (209.249.11.37)  98.160 ms  98.714 ms  97.471 ms
#   17  vlan905.core5.iad2.rackspace.net (72.4.122.10)  99.976 ms  99.873 ms  99.243 ms
#   18  aggr301a-1-core5.iad2.rackspace.net (72.4.122.121)  97.807 ms  100.763 ms  99.974 ms


