Stella - Your Performance Testing Friend

Release: 0.5.3-preview (2008-12-23)

This is a PREVIEW release. Don't trust and double verify!


== Prerequisites

* Linux, *BSD, Solaris
* Ruby 1.8.x or 1.9.x
* Ruby Libraries
  * fastthread
	* mongrel
	* rspec
	* rdoc
	
* One of:
  * Apache Bench
  * Siege
  * Httperf


== Installation

Get it in one of the following ways:
* RubyForge: http://stella.rubyforge.org/
* gem install stella 
  
Use ab, siege, and httperf like you normally would with the addition of stella at the beginning (examples are below).

=== Debian (and derivatives)

Debian and its derivative (Ubunutu) handling packing a bit differently (see: http://pkg-ruby-extras.alioth.debian.org/rubygems.html). There are a couple errors to watch out for during the installation. The solutions are below:

"no such file to load -- mkmf (LoadError)"
  
	apt-get install ruby1.8-dev

"ERROR: RDoc documentation generator not installed!"
  
	apt-get install rdoc


== Examples

Run Apache Bench with a warmup and rampup from 100 to 300 virtual users in increments of 25

  stella --warmup=0.5 --rampup=25,300 ab -c 100 -n 10000 http://stellaaahhhh.com/search?term=trooper
    

Run Siege, repeat the test 5 times. Automatically creates a summary averages and standard deviations. 

  stella --agent=ff-3-osx --testruns=5  siege -c 100 -r 100 -b http://stellaaahhhh.com/search?term=flock+of+seagulls
    

Run Httperf like you normally would (but all the test data will be collected for you)

  stella httperf --hog --client=0/1 --server=127.0.0.1 --port=5600 --uri=/ --rate=50  --num-conns=3000 --timeout=5


== Sample Output

  $ stella -f csv -x 5 -w 0.75 -r 25,125 -m "httpd 2.2.9-prefork" siege -c 75 -r 10 -b http://stella:5600/
	Writing test data to: stella/testruns/2008-12-23/test-054

	  Warmup:       3750@37/1   100%    264.29/s    0.140s    0.024MB/s    0.340MB   14.000s .

	 -------------------------------------------------------------------
	                 REQ@VU/s  AVAIL       REQ/s     RTIME       DATA/s       DATA      TIME

	  Run 01:       7500@75/1   100%    345.30/s    0.210s    0.032MB/s    0.690MB   21.720s
	  Run 02:       7500@75/1   100%    360.58/s    0.200s    0.033MB/s    0.690MB   20.800s
	  Run 03:       7500@75/1   100%    359.02/s    0.210s    0.033MB/s    0.690MB   20.890s
	 -------------------------------------------------------------------
	   Total:      22500@73     100%    354.97/s    0.207s    0.033MB/s    2.070MB   63.410s
	 Std Dev:                             6.86/s    0.005s    0.001MB/s               0.414s

	  Run 04:      10000@100/1  100%    384.47/s    0.260s    0.035MB/s    0.920MB   26.010s
	  Run 05:      10000@100/1  100%    385.06/s    0.260s    0.035MB/s    0.920MB   25.970s
	  Run 06:      10000@100/1  100%    380.95/s    0.260s    0.035MB/s    0.920MB   26.250s
	 -------------------------------------------------------------------
	   Total:      30000@98     100%    383.49/s    0.260s    0.035MB/s    2.760MB   78.230s
	 Std Dev:                             1.81/s    0.000s    0.000MB/s               0.124s

	  Run 07:      12500@125/1  100%    397.20/s    0.310s    0.036MB/s    1.140MB   31.470s
	  Run 08:      12500@125/1  100%    397.08/s    0.310s    0.036MB/s    1.140MB   31.480s
	  Run 09:      12500@125/1  100%    397.58/s    0.310s    0.036MB/s    1.140MB   31.440s
	 -------------------------------------------------------------------
	   Total:      37500@123    100%    397.29/s    0.310s    0.036MB/s    3.420MB   94.390s
	 Std Dev:                             0.21/s    0.000s    0.000MB/s               0.017s

	 -------------------------------------------------------------------
	   Total:      90000@98     100%    378.58/s    0.259s    0.035MB/s    8.250MB  236.030s
	 Std Dev:                            18.09/s    0.042s    0.002MB/s               4.225s


All test data is collected under ./stella (this can be changed with the parameter --datapath):

  $ ls -l ./stella/testruns/2008-12-23/
  test-001   test-002   test-003   test-004   test-005   test-006  ...  test-054
  

A symbolic link points to the most recent test:

  $ ls -l ./stella/latest/
  ID.txt    MESSAGE.txt  SUMMARY.csv  run01    run02    run03    run04    run05    warmup
  

Each run directory contains all associated data, including the command and configuration

  $ ls -l ./stella/latest/run01/
    COMMAND.txt    STDOUT.txt    siege.log    STDERR.txt    SUMMARY.csv    siegerc
    
  
== Known Issues

* The output for the REQ@VU/s columns is a work in progress. It's not aligned across tools and it will likely change in the next release. 
* The summary data has not been audited. Don't trust and double verify!
* httperf is functional but needs a lot more testing (most dev was done with ab and siege).
* The Ruby API has not been finalized. It's functional but there's no example because it is subject to change. 
* There are no specs. 

== Report an issue

Email issues and bugs to stella@solutious.com


== Even More Information

http://www.youtube.com/watch?v=wmq-JDonTpc

== License

See LICENSE.txt