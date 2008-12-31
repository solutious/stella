


module Stella
  module Adapter

    #Usage: ab [options] [http[s]://]hostname[:port]/path
    #Options are:
    #    -n requests     Number of requests to perform
    #    -c concurrency  Number of multiple requests to make
    #    -t timelimit    Seconds to max. wait for responses
    #    -b windowsize   Size of TCP send/receive buffer, in bytes
    #    -p postfile     File containing data to POST. Remember also to set -T
    #    -T content-type Content-type header for POSTing, eg.
    #                    'application/x-www-form-urlencoded'
    #                    Default is 'text/plain'
    #    -v verbosity    How much troubleshooting info to print
    #    -w              Print out results in HTML tables
    #    -i              Use HEAD instead of GET
    #    -x attributes   String to insert as table attributes
    #    -y attributes   String to insert as tr attributes
    #    -z attributes   String to insert as td or th attributes
    #    -C attribute    Add cookie, eg. 'Apache=1234. (repeatable)
    #    -H attribute    Add Arbitrary header line, eg. 'Accept-Encoding: gzip'
    #                    Inserted after all normal header lines. (repeatable)
    #    -A attribute    Add Basic WWW Authentication, the attributes
    #                    are a colon separated username and password.
    #    -P attribute    Add Basic Proxy Authentication, the attributes
    #                    are a colon separated username and password.
    #    -X proxy:port   Proxyserver and port number to use
    #    -V              Print version number and exit
    #    -k              Use HTTP KeepAlive feature
    #    -d              Do not show percentiles served table.
    #    -S              Do not show confidence estimators and warnings.
    #    -g filename     Output collected data to gnuplot format file.
    #    -e filename     Output CSV file with percentages served
    #    -r              Don't exit on socket receive errors.
    #    -h              Display usage information (this message)
    #    -Z ciphersuite  Specify SSL/TLS cipher suite (See openssl ciphers)
    #    -f protocol     Specify SSL/TLS protocol (SSL2, SSL3, TLS1, or ALL)
    class ApacheBench < Stella::Adapter::Base
      
      
      attr_accessor :n, :c, :t, :b, :p, :T, :v, :w, :i, :x, :z, :y
      attr_accessor :C, :H, :A, :P, :X, :V, :k, :d, :S, :e, :g, :r, :h, :Z, :f
      
      def initialize(options={}, arguments=[])
        super(options, arguments)
        @private_variables = ['private_variables', 'name', 'arguments', 'load_factor', 'working_directory']
        @c = 1
        @n = 1
        @name = 'ab'
        @load_factor = 1
      end
      
      
      def version
        vsn = 0
        Stella::Util.capture_output("#{@name} -V") do |stdout, stderr|
           stdout.join.scan(/Version (\d+?\.\d+)/) { |v| vsn = v[0] }
        end
        vsn
      end
      
      def before
        
        @e = @working_directory + "/ab-percentiles.log" 
        @e = File.expand_path(@e)

        @g = @working_directory + "/ab-requests.log" 
        @g = File.expand_path(@g)

      end
      
      def command
        raise CommandNotReady.new(self.class.to_s) unless ready?

        command = "#{@name} "

        instance_variables.each do |name|
          canon = name.to_s.tr('@', '')        # instance_variables returns '@name'
          next if @private_variables.member?(canon)

          # It's important that we take the value from the getter method
          # because it applies the load factor. 
          value = self.send(canon)
          if (value.is_a? Array)
            value.each { |el| command << "-#{canon} #{EscapeUtil.shell_single_word(el.to_s)} " }
          else
            command << "-#{canon} #{EscapeUtil.shell_single_word(value.to_s)} "
          end

        end

        command << (@arguments.map { |uri| "#{uri}" }).join(' ') unless @arguments.empty?
        command
      end
      # loadtest
      #
      # True or false: is the call to ab a load test? If it's a call to help or version or
      # to display the config this with return false. It's no reason for someone to make this 
      # call through Stella but it's here for goodness sake. 
      def loadtest?
        !@arguments.empty?  # The argument is a URI
      end
      def ready?
        (!self.loadtest?) || (@name && !instance_variables.empty? && !@arguments.empty?)
      end
      
      
      def process_options(arguments)
        options = OpenStruct.new
        opts = OptionParser.new 
        opts.on('-v') do |v| options.v = true end
        opts.on('-w') do |v| options.w = true end # TODO: Print a note that we don't parse the HTML results
        opts.on('-i') do |v| options.i = true end
        opts.on('-V') do |v| options.V = true end
        opts.on('-k') do |v| options.k = true end
        opts.on('-d') do |v| options.d = true end
        opts.on('-S') do |v| options.S = true end
        opts.on('-r') do |v| options.r = true end
        opts.on('-h') do |v| options.h = true end
        opts.on('-e S', String) do |v| options.e = v end
        opts.on('-g S', String) do |v| options.g = v end
        opts.on('-p S', String) do |v| options.p = v end
        opts.on('-T S', String) do |v| options.t = v end
        opts.on('-x S', String) do |v| options.x = v end
        opts.on('-y S', String) do |v| options.y = v end
        opts.on('-z S', String) do |v| options.z = v end
        opts.on('-P S', String) do |v| options.P = v end
        opts.on('-Z S', String) do |v| options.Z = v end
        opts.on('-f S', String) do |v| options.f = v end
        opts.on('-c N', Integer) do |v| options.c = v end
        opts.on('-n N', Integer) do |v| options.n = v end
        opts.on('-t N', Integer) do |v| options.t = v end
        opts.on('-b N', Integer) do |v| options.b = v end
        opts.on('-H S', String) do |v| options.H ||= []; options.H << v; end
        opts.on('-C S', String) do |v| options.C ||= []; options.C << v; end
        
        # NOTE: parse! removes the options it finds in @arguments. It will leave
        # all unnamed arguments and throw a fit about unknown ones. 
        opts.parse!(arguments)
        
        options
      rescue OptionParser::InvalidOption => ex
        # We want to replace this text so we grab just the name of the argument
        badarg = ex.message.gsub('invalid option: ', '')
        raise InvalidArgument.new(badarg)
      end

      def after
        # We want to maintain copies of all test output, even when the user has 
        # supplied other path names so we'll copy the files from the testrun directory
        # to the location specified by the user
        [[@options.e, 'csv'], [@options.g, 'tsv']].each do |tuple|
          if File.expand_path(File.dirname(tuple[0])) != File.expand_path(@runpath)
            from = tuple[0]
            to = @runpath + "/ab-#{tuple[1]}.log"
            next unless File.exists?(from)
            File.copy(from, to)
          end
        end

        save_stats
      end



      
      def add_header(name, value)
        @H ||= []
        @H << "#{name}: #{value}"
      end
      
      def user_agent=(list=[])
        return unless list && !list.empty?
        list = list.to_ary
        list.each do |agent|
          add_header("User-Agent", agent)
        end
      end
      
      def vusers
        c || 0
      end
      def vusers=(v)
        ratio = vuser_requests
        @c = v
        @n = ratio * @c
      end
      def requests
        n || 0
      end
      def requests=(v)
        @n = v
      end
      def vuser_requests
        ratio = 1
        # The request ratio tells us how many requests will be
        # generated per vuser. It helps us later when we need to
        # warmp up and ramp up.
        if @n > 0 && @c > 0
          ratio = (@n.to_f / @c.to_f).to_f
        # If concurrency isn't set, we'll assume the total number of requests
        # is intended to be per request
        elsif @n > 0
         ratio = @n
        end
        ratio
      end
      def c
        (@c * @load_factor).to_i
      end
      def n
        (@n * @load_factor).to_i
      end

      def hosts
        hosts = @arguments || []
        #hosts << get_hosts_from_file
        hosts = hosts.map{ |h| tmp = URI.parse(h.strip); "#{tmp.host}:#{tmp.port}" }
        hosts
      end

      def paths
        paths = @arguments || []
        #hosts << get_hosts_from_file
        paths = paths.map{ |h| tmp = URI.parse(h.strip); "#{tmp.path}?#{tmp.query}" }
        paths
      end


      
      # Apache bench writes the summary to STDOUT
      def stats_file
        File.new(stdout_path)
      end

      def stats
        return unless stats_file
        raw = {}
        stats_file.each_line { |l|
          l.chomp!
          nvpair = l.split(':')
          next unless nvpair && nvpair.size == 2
          n = nvpair[0].strip.tr(' ', '_').downcase[/\w+/]
          v = nvpair[1].strip[/[\.\d]+/]
          
          # Apache Bench outputs two fields with the name "Time per request".
          # We want only the first one so we don't overwrite values.
          raw[n.to_sym] = v.to_f  unless raw.has_key? n.to_sym
        }

        # Document Path:          /
        # Document Length:        96 bytes
        # 
        # Concurrency Level:      75
        # Time taken for tests:   2.001 seconds
        # Complete requests:      750
        # Failed requests:        0
        # Write errors:           0
        # Total transferred:      174000 bytes
        # HTML transferred:       72000 bytes
        # Requests per second:    374.74 [#/sec] (mean)
        # Time per request:       200.138 [ms] (mean)
        # Time per request:       2.669 [ms] (mean, across all concurrent requests)
        # Transfer rate:          84.90 [Kbytes/sec] received

        stats = Stella::Test::Run::Summary.new

        unless raw.empty? || !raw.has_key?(:time_taken_for_tests)

          stats.elapsed_time = raw[:time_taken_for_tests]

          # We want this in MB, Apache Bench gives Bytes. 
          stats.data_transferred = ((raw[:html_transferred] || 0) / 1_048_576)

          # total_transferred is header data + response data (html_transfered)
          stats.headers_transferred = ((raw[:total_transferred] || 0) / 1_048_576) - stats.data_transferred

          # Apache Bench returns ms
          stats.response_time = (raw[:time_per_request] || 0) / 1000
          stats.transaction_rate = raw[:requests_per_second]

          stats.vusers = raw[:concurrency_level].to_i
          stats.successful = raw[:complete_requests].to_i
          stats.failed = raw[:failed_requests].to_i

          stats.transactions = stats.successful + stats.failed

          #stats.raw = raw  if @global_options.debug
        end

        stats
      end



    end
    
  end
end