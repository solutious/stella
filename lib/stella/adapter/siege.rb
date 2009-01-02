

module Stella
  module Adapter

    # SIEGE 
    # Usage: siege [options]
    #        siege [options] URL
    #        siege -g URL
    # Options:
    #   -V, --version           VERSION, prints version number to screen.
    #   -h, --help              HELP, prints this section.
    #   -C, --config            CONFIGURATION, show the current configuration.
    #   -v, --verbose           VERBOSE, prints notification to screen.
    #   -g, --get               GET, pull down headers from the server and display HTTP
    #                           transaction. Great for web application debugging.
    #   -c, --concurrent=NUM    CONCURRENT users, default is 10
    #   -u, --url="URL"         Deprecated. Set URL as the last argument.
    #   -i, --internet          INTERNET user simulation, hits the URLs randomly.
    #   -b, --benchmark         BENCHMARK, signifies no delay for time testing.
    #   -t, --time=NUMm         TIME based testing where "m" is the modifier S, M, or H
    #                           no space between NUM and "m", ex: --time=1H, one hour test.
    #   -r, --reps=NUM          REPS, number of times to run the test, default is 25
    #   -f, --file=FILE         FILE, change the configuration file to file.
    #   -R, --rc=FILE           RC, change the siegerc file to file.  Overrides
    #                           the SIEGERC environmental variable.
    #   -l, --log               LOG, logs the transaction to PREFIX/var/siege.log
    #   -m, --mark="text"       MARK, mark the log file with a string separator.
    #   -d, --delay=NUM         Time DELAY, random delay between 1 and num designed
    #                           to simulate human activity. Default value is 3
    #   -H, --header="text"     Add a header to request (can be many)
    #   -A, --user-agent="text" Sets User-Agent in request
    class Siege < Stella::Adapter::Base
      
      attr_writer :reps, :concurrent, :version
      attr_reader :user_agent
      attr_accessor :help, :config, :verbose, :get, :log, :mark, :delay, :header
      attr_accessor :rc, :file, :time, :benchmark, :internet
      
      def initialize(options={}, arguments=[])
        super(options, arguments)
        @name = 'siege'
        @reps = 1
        @concurrent = 1
        @private_variables = ['private_variables', 'name', 'arguments', 'load_factor', 'working_directory', 'orig_logfile']
        @load_factor = 1
        
        @rc = File.join(ENV['HOME'] || ENV['USERPROFILE'], '.siegerc')
        
        # Siege won't run unless there's a siegerc file. If the default one doesn't exist
        # we need to call siege.config to create it. This should only happen once. 
        # We use capture_output here so STDOUT and STDERR don't print to the screen. 
        Stella::Util.capture_output("#{@name}.config") do 'nothing' end unless File.exists? @rc
      end
      
      def version
        vsn = 0
        Stella::Util.capture_output("#{@name} --version") do |stdout, stderr|
           stderr.join.scan(/SIEGE (\d+?\.\d+)/) { |v| vsn = v[0] }
        end
        vsn
      end
      
      # loadtest
      #
      # True or false: is the call to siege a load test? If it's a call to help or version or
      # to display the config this with return false. It's no reason for someone to make this 
      # call through Stella but it's here for goodness sake. 
      def loadtest?
        !@arguments.empty?  # The argument is a URI
      end
      
      def ready?
        @name && !instance_variables.empty? 
      end
      

      # Before calling run
      def before

        # Keep a copy of the configuration file. 
        copy_siegerc

        # Keep a copy of the URLs file.
        copy_urls_file if @file
        
        # TODO: Print message about neither --benchmark or --internet
      end
      def command
        raise CommandNotReady.new(self.class.to_s) unless ready?

        command = "#{@name} "

        instance_variables.each do |name|
          canon = name.tr('@', '')        # instance_variables returns '@name'
          next if @private_variables.member?(canon)

          # It's important that we take the value from the getter method
          # because it applies the load factor. 
          value = self.send(canon)
          if (value.is_a? Array)
            value.each { |el| command << "--#{canon.tr('_', '-')} #{EscapeUtil.shell_single_word(el.to_s)} " }
          else
            command << "--#{canon.tr('_', '-')} #{EscapeUtil.shell_single_word(value.to_s)} "
          end

        end

        command << (@arguments.map { |uri| "'#{uri}'" }).join(' ') unless @arguments.empty?
        command
      end
      
      # After calling run
      def after

        update_orig_logfile if @orig_logfile

        save_stats
      end


      def process_options(arguments)
        options = OpenStruct.new
        opts = OptionParser.new 
        opts.on('-V', '--version') do |v| @version = v end
        opts.on('-h', '--help') do |v| @help = v end
        opts.on('-C', '--config') do |v| @config = v end
        opts.on('-v', '--verbose') do |v| @verbose = v end
        opts.on('-g', '--get') do |v| @get = v end
        opts.on('-l', '--log') do |v| @log = v end
        opts.on('-m S', '--mark=S', String) do |v| @mark = v end
        opts.on('-d N', '--delay=N', Float) do |v| @delay = v end
        opts.on('-H S', '--header=S', String) do |v| @header ||= []; @header << v end
          
        opts.on('-r N', '--reps=N', Integer) do |v| @reps = v.to_i end
        opts.on('-c N', '--concurrent=N', Integer) do |v| @concurrent = v.to_i end
        opts.on('-R S', '--rc=S', String) do |v| @rc = v end
        opts.on('-f S', '--file=S', String) do |v| @file = v end
        opts.on('-t S', '--time=S', String) do |v| @time = v end
        opts.on('-b', '--benchmark') do |v| @benchmark = true;  end
        opts.on('-i', '--internet') do |v| @internet = true; end
        opts.on('-A S', '--user-agent=S', String) do |v| @user_agent ||= []; @user_agent << v end

        raise "You cannot select both --internet and --benchmark" if options.internet && options.benchmark

        # parse! removes the options it finds.
        # It also fails when it finds unknown switches (i.e. -X)
        # Which should leave only the remaining arguments (URIs in this case)
        opts.parse!(arguments)
        options
      rescue OptionParser::InvalidOption => ex
        # We want to replace this text so we grab just the name of the argument
        badarg = ex.message.gsub('invalid option: ', '')
        raise InvalidArgument.new(badarg)
      end

      
      def add_header(name, value)
        @header ||= []
        @header << "#{name}: #{value}"
      end
      def user_agent=(list=[])
        return unless list && !list.empty?
        list = list.to_ary
        @user_agent ||= []
        @user_agent << list
        @user_agent.flatten
      end
      
      def vusers
        concurrent || 0 
      end
      def vusers=(v)
        @concurrent = v
      end
      def requests
        (@reps * concurrent_f).to_i
      end
      def requests=(v)
        @reps = (v / concurrent_f).to_i
      end
      def vuser_requests
        @reps
      end
      
      def concurrent
        (@concurrent * @load_factor).to_i
      end
      def concurrent_f
        (@concurrent * @load_factor).to_f
      end
      def reps
        @reps
      end
      
      
      # Take the last line of the siege.log file and write it to the log file
      # specified by the user. We don't this so running with Stella is 
      # identical to running it standalone
      def update_orig_logfile

        return unless (@orig_logfile)
        log_str = FileUtil.read_file_to_array(log_file) || ''
        return if log_str.empty?

        if File.exists?(@orig_logfile)
          FileUtil.append_file(@orig_logfile, log_str[-1], true)
        else  
          FileUtil.write_file(@orig_logfile, log_str.join(''), true)
        end

      end

      # We want to keep a copy of the configuration file and also
      # modify it a little bit to make sure we get all the mad info from siege
      def copy_siegerc

        # Read in the siegerc file so we can manipulate it
        siegerc_str = FileUtil.read_file(File.expand_path(@rc))

        siegerc_vars = {
          :verbose => [false, true],    # We want to maximize the data output by siege
          :logging => [false, true], 
          :csv => [false, true]
        }

        #if (@agent)
        #  siegerc_vars['user-agent'] = ['.*', 'dogs2']
        #end

        # We'll set the variables in the siegerc file
        siegerc_vars.each_pair do |var,value|
          siegerc_str.gsub!(/#{var}\s*=\s*#{value[0]}/, "#{var} = #{value[1]}")  # make true
          siegerc_str.gsub!(/^\#+\s*#{var}/, "#{var}")              # remove comment
        end

        # Look for the enabled logile path
        # We will use this later to update it from the last line in our copy
        siegerc_str =~ /^\s*logfile\s*=\s*(.+?)$/
        @orig_logfile = $1 || nil

        # Replace all environment variables with literal values
        @orig_logfile.gsub!(/\$\{#{$1}\}/, ENV[$1]) while (@orig_logfile =~ /\$\{(.+?)\}/ && ENV.has_key?($1))

        @orig_logfile = File.expand_path(@orig_logfile) if @orig_logfile
        

        siegerc_str.gsub!(/^\#*\s*logfile\s*=\s*.*?$/, "logfile = " + log_file)
        
        FileUtil.write_file(rc_file, siegerc_str, true)
        @rc = rc_file
      end

      # We want to keep a copy of the URLs file too
      def copy_urls_file
        if @file
          File.copy(File.expand_path(@file), uris_file) 
          @file = uris_file
        end
      end

      # Siege writes the summary to STDERR
      def stats_file
        File.new(stderr_path)
      end
      
      def rc_file
        File.join(@working_directory, "siegerc")
      end
      
      def log_file
        File.join(@working_directory, "siege.log")
      end
      
      def uris_file
        File.join(@working_directory, File.basename(@file))
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
          raw[n.to_sym] = v.to_f
        }

        stats = Stella::Test::Run::Summary.new
        
        # Transactions:		         750 hits
        # Availability:		      100.00 %
        # Elapsed time:		        2.33 secs
        # Data transferred:	        0.07 MB
        # Response time:		        0.21 secs
        # Transaction rate:	      321.89 trans/sec
        # Throughput:		        0.03 MB/sec
        # Concurrency:		       67.49
        # Successful transactions:         750
        # Failed transactions:	           0
        # Longest transaction:	        0.33
        # Shortest transaction:	        0.10
        
        stats.vusers = raw[:concurrency]
        stats.data_transferred = raw[:data_transferred]
        stats.elapsed_time = raw[:elapsed_time]
        stats.response_time = raw[:response_time]
        stats.transactions = raw[:transactions].to_i
        stats.transaction_rate = raw[:transaction_rate]
        stats.failed = raw[:failed_transactions].to_i
        stats.successful = raw[:successful_transactions].to_i
        
        #stats.shortest_transaction = raw[:shortest_transaction]
        #stats.longest_transaction = raw[:longest_transaction]
        
        stats
      end



    end
  end
end