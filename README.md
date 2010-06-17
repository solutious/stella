# Stella - 0.8 BETA

**Blame Stella for breaking your web application!**

Stella is an integration and load testing tool. It fits well into an agile development process because the configuration syntax is simple yet powerful and a single config can be used for both kinds of tests (integration and load). Stella runs at the protocol-level which means it generates HTTP requests and parses the responses but does not perform any browser simulation (see Caveats).

### Important Information Regarding Your Testplans

*The testplan configuration syntax changed a little in 0.8. Most configs will not be affected. See "News" below for more info.*

## Features

* Support for simulating multiple usecases at the same time
* Sophisticated response handling 
* Automatic parsing of HTML, XML, XHTML, YAML, and JSON response bodies
* Dynamic variable replacement 
* Support for testing multiple sites simultaneously


## Caveats

There are a few known limitations:

* *POSSIBLE SHOW-STOPPER*: An upper limit of around 200-300 concurrent virtual HTTP clients. There is a threading issue in the HTTPClient library which appears under high load. 
* *POSSIBLE SHOW-STOPPER*: No support for browser or UI based tests (a la Watir or Selenium). If this is a show stopper for you, check out [WatirGrid](http://github.com/90kts/watirgrid)
* *ANNOYING*: File uploads do not work with some HTTP servers (WEBrick)
* *ANNOYING*: Lack of documentation (see examples/ directory)
* *ANNOYING*: Reporting is limited to log files and command-line output. You need to make your own graphs. 


## Examples


### Testplan Configuration

Every load testing tool worth its salt allows you to control the logical flow with some form of programming language. One of the advantages that open source tools have over commercial ones is that the languages used are generally well known whereas most commercial tools use proprietary languages. This makes it possible to define sophisticated and realistic tests.

Stella test plans are defined in subset of the Ruby programming language. They also typically contain more than one usecase which is important when simulating realistic load. 

    usecase "An Example Usecase" do
      get '/some/path' do
        param :what  => 'food'
        param :where => 'iowa'
        response 200 do
          # code executed when the server returns a 200 response. 
        end
      end
      
      get '/a/dynamic/:path' do    
        param :path => random(4)   # => http://host/a/dynamic/jrr1
      end
    end
    
    
See the [examples/](http://github.com/solutious/stella/tree/0.8/examples/) directory and [Getting Started](http://solutious.com/projects/stella/getting-started/) for more information. 


### Running Tests

Stella is a command-line tool with two main commands: "verify" for integration tests and "generate" for load tests. 

    # Verify a test plan is defined correctly
    # by running a single user functional test.
    $ stella verify -p examples/essentials/plan.rb http://stellaaahhhh.com/
    
    # Generate load using the same test plan. 
    $ stella generate -p examples/essentials/plan.rb -c 50 -d 10m http://stellaaahhhh.com/
    

See <tt>$ stella -h</tt> and <tt>$ stella example</tt> for more info. 

## News

### 2010-01-16: sequential, random, rsequential etc... methods now return ERB-style templates instead of Procs

Pre-0.8 would return a Proc that would be evaluated at request time:

    get "/" do
      param :salt => random(8)    # => "#<Proc0x13423c0 ...>"
    end
    
In 0.8 and beyond, the same configuration will return a String:

    get "/" do
      param :salt => random(8)    # => "<%= random(8) %>"
    end

## Installation

Get it in one of the following ways:
     
    $ gem install stella --source=http://gemcutter.org/
    $ sudo gem install stella --source=http://gemcutter.org/
    $ git clone git://github.com/solutious/stella.git

You can also download via [tarball](http://github.com/solutious/stella/tarball/latest) or [zip](http://github.com/solutious/stella/zipball/latest). 

NOTE: If you get errors about libxml2 or libxslt on Ubuntu, you need to install the following:

    sudo apt-get install libxml2-dev
    sudo apt-get install libxslt1-dev


## More Information

* [Homepage](http://solutious.com/projects/stella)
* [Codes](http://github.com/solutious/stella)
* [RDocs](http://solutious.com/stella)
* [Stellaaahhhh](http://stellaaahhhh.com)
* [Using Stella for Web application testing](http://searchsoftwarequality.techtarget.com/tip/0,289483,sid92_gci1510488,00.html)


## Credits

* [Delano Mandelbaum](http://solutious.com)


## Thanks 

* Harm Aarts for the great test case and feedback!
* Kalin Harvey for keeping me on track.
* Dave L, the best intern money can't buy. 
* Peter McCurdy for the feedback and bug fixes. 


## Related Projects

* [WatirGrid](http://github.com/90kts/watirgrid)
* [Watir](http://watir.com/)
* [JMeter](http://jakarta.apache.org/jmeter/)
* [Tsung](http://tsung.erlang-projects.org/)
* [Grinder](http://grinder.sourceforge.net/)
* [Pylot](http://www.pylot.org/)
* [Trample](http://github.com/jamesgolick/trample)

## License

See LICENSE.txt
