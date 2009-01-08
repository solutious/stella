

module Stella
  module Adapter

    #Usage: httperf [-hdvV] [--add-header S] [--burst-length N] [--client N/N]
    #	[--close-with-reset] [--debug N] [--failure-status N]
    #	[--help] [--hog] [--http-version S] [--max-connections N]
    #	[--max-piped-calls N] [--method S] [--no-host-hdr]
    #	[--num-calls N] [--num-conns N] [--period [d|u|e]T1[,T2]]
    #	[--port N] [--print-reply [header|body]] [--print-request [header|body]]
    #	[--rate X] [--recv-buffer N] [--retry-on-failure] [--send-buffer N]
    #	[--server S] [--server-name S] [--session-cookies]
    #	[--ssl] [--ssl-ciphers L] [--ssl-no-reuse]
    #	[--think-timeout X] [--timeout X] [--uri S] [--verbose] [--version]
    #	[--wlog y|n,file] [--wsess N,N,X] [--wsesslog N,X,file]
    #	[--wset N,X]
    # 
    class Httperf < Stella::Adapter::Base
      
      
      
      attr_accessor :hog, :server, :uri, :num_conns, :num_calls, :rate, :timeout, :think_timeout, :port
      attr_accessor :burst_length, :client, :close_with_reset, :debug, :failure_status
      attr_accessor :help, :http_version, :max_connections, :max_piped_calls, :method, :no_host_hdr
      attr_accessor :period, :print_reply, :print_request, :recv_buffer, :retry_on_failure, :send_buffer
      attr_accessor :server_name, :session_cookies, :ssl, :ssl_ciphers, :ssl_no_reuse, :verbose 
      
      attr_writer :version, :add_header, :wlog, :wsess, :wsesslog, :wset
      
      def initialize(options={}, arguments=[])
        super(options, arguments)
        @name = 'httperf'
        
        @private_variables = ['private_variables', 'name', 'arguments', 'load_factor', 'working_directory']
        @load_factor = 1
      end
      
      
      
      def error
        (File.exists? stderr_path) ? FileUtil.read_file(stderr_path) : "Unknown error"
      end
      
      # Before calling run
      def before

        
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


        save_stats
      end

      #httperf --hog --server=queen --uri=/0k.html --num-conns=10000 --rate=0 --timeout=30 --think-timeout=0
      def process_options(arguments)
        
        options = OpenStruct.new
        opts = OptionParser.new 
        opts.on('--hog') do @hog = true end
        opts.on('--server=S', String) do |v| @server = v end
        opts.on('--server-name=S', String) do |v| @server_name = v end
        opts.on('--port=N', Integer) do |v| @port = v end
        opts.on('--uri=S', String) do |v| @uri = v end
        opts.on('--num-conns=N', Integer) do |v| @num_conns = v end
        opts.on('--num-calls=N', Integer) do |v| @num_calls = v end
        opts.on('--rate=N', Integer) do |v| @rate = v end
        opts.on('--timeout=N', Integer) do |v| @timeout = v end
        opts.on('--think-timeout=N', Integer) do |v| @think_timeout = v end
        
        opts.on('-h', '--help') do |v| @help = true end
        opts.on('-v', '--verbose') do |v| @verbose = true end
        opts.on('-V', '--version') do |v| @version = true end
        opts.on('--close-with-reset') do |v| @close_with_reset = true end
        opts.on('--session-cookies') do |v| @session_cookies = true end
        opts.on('--ssl') do |v| @ssl = true end
        opts.on('--ssl-ciphers') do |v| @ssl_ciphers = true end
        opts.on('--ssl-no-reuse') do |v| @ssl_no_reuse = true end
        opts.on('--no-host-hdr') do |v| @no_host_hdr = true end
        opts.on('--retry-on-failure') do |v| @retry_on_failure = true end
              
        opts.on('--add-header=S', String) do |v| @add_header ||= []; @add_header << v; end
        opts.on('--burst-length=N', Integer) do |v| @burst_length = v end
        opts.on('--client=S', String) do |v| @client = v end
        opts.on('-d N', '--debug=N', Integer) do |v| @debug ||= 0; @debug = v end
        opts.on('--failure-status=N', Integer) do |v| @failure_status = v end
        
        opts.on('--http-version=S', String) do |v| @http_version = v end
        
        opts.on('--max-connections=N', Integer) do |v| @max_connections = v end
        opts.on('--max-piped-calls=N', Integer) do |v| @max_piped_calls = v end
        opts.on('--method=S', String) do |v| @method = v end
        
        opts.on('--period=S', String) do |v| @period = v end # TODO: Requires parsing
        opts.on('--print-reply=[S]', String) do |v| @print_reply = v end
        opts.on('--print-request=[S]', String) do |v| @print_request = v end
          
        opts.on('--recv-buffer=N', Integer) do |v| @recv_buffer = v end
        opts.on('--send-buffer=N', Integer) do |v| @send_buffer = v end
        
        
        opts.on('--wlog=S', String) do |v| @wlog = Stella::Util::expand_str(v) end
        opts.on('--wsess=S', String) do |v| @wsess = Stella::Util::expand_str(v) end
        opts.on('--wsesslog=S', String) do |v| @wsesslog = Stella::Util::expand_str(v) end
        opts.on('--wset=S', String) do |v| @wset = Stella::Util::expand_str(v) end
          
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

      
      def version
        vsn = 0
        Stella::Util.capture_output("#{@name} --version") do |stdout, stderr|
           stdout.join.scan(/httperf\-([\d\.]+)\s/) { |v| vsn = v[0] }
        end
        vsn
      end
      
      # loadtest
      #
      # True or false: is the call to siege a load test? If it's a call to help or version or
      # to display the config this with return false. It's no reason for someone to make this 
      # call through Stella but it's here for goodness sake. 
      def loadtest?
        @uri && !@uri.empty?
      end
      def ready?
        @name && !instance_variables.empty?
      end
      
      def add_header(name=false, value=false)
        # This is a hack since we have an instance variable called add_header.
        # I figure this is the best of two evils because I'd rather keep the 
        # instance variable naming consistent. 
        return @add_header if !name && !value 
        @add_header ||= []
        @add_header << "#{name}: #{value}"
      end
      
      def user_agent=(list=[])
        return unless list && !list.empty?
        list = list.to_ary
        list.each do |agent|
          add_header("User-Agent", agent)
        end
      end
      def vusers
         @rate
      end
      def vusers=(v)
        0
      end
      def requests
        @num_conns # TODO: also check wsess and wlog params
      end
      def requests=(v)
        0
      end
      def vuser_requests
        0
      end
      def wsess
        @wsess.join(',')
      end
      
      def wset
        @wset.join(',')
      end
      
      
      def wsesslog
        @wsesslog.join(',')
      end
      def wlog
        @wlog.join(',')
      end
      
      #def concurrent
      #  (@concurrent * @load_factor).to_i
      #end
      #def concurrent_f
      #  (@concurrent * @load_factor).to_f
      #end
      #def reps
      #  @reps
      #end
      
      

      # Siege writes the summary to STDERR
      def stats_file
        File.new(stdout_path) if File.exists?(stdout_path)
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
      
      # httperf --hog --timeout=30 --client=0/1 --server=127.0.0.1 --port=5600 --uri=/ --send-buffer=4096 --recv-buffer=16384 --num-conns=5 --num-calls=1
      # httperf: warning: open file limit > FD_SETSIZE; limiting max. # of open files to FD_SETSIZE
      # Maximum connect burst length: 1
      # 
      # Total: connections 5 requests 5 replies 5 test-duration 0.513 s
      # 
      # Connection rate: 9.7 conn/s (102.7 ms/conn, <=1 concurrent connections)
      # Connection time [ms]: min 102.1 avg 102.7 max 104.1 median 102.5 stddev 0.8
      # Connection time [ms]: connect 0.2
      # Connection length [replies/conn]: 1.000
      # 
      # Request rate: 9.7 req/s (102.7 ms/req)
      # Request size [B]: 62.0
      # 
      # Reply rate [replies/s]: min 0.0 avg 0.0 max 0.0 stddev 0.0 (0 samples)
      # Reply time [ms]: response 102.3 transfer 0.1
      # Reply size [B]: header 136.0 content 96.0 footer 0.0 (total 232.0)
      # Reply status: 1xx=0 2xx=5 3xx=0 4xx=0 5xx=0
      # 
      # CPU time [s]: user 0.12 system 0.39 (user 22.5% system 75.3% total 97.8%)
      # Net I/O: 2.8 KB/s (0.0*10^6 bps)
      # 
      # Errors: total 0 client-timo 0 socket-timo 0 connrefused 0 connreset 0
      # Errors: fd-unavail 0 addrunavail 0 ftab-full 0 other 0
      
      def stats
        return unless stats_file
        
        raw = stats_file.readlines.join
        stats = Stella::Test::Run::Summary.new
        
        raw.scan(/Request rate: (\d+?\.\d+?) req.s .(\d+?\.\d+?) ms.req./) do |rate,time|
          stats.transaction_rate = rate.to_f
          stats.response_time = (time.to_f) / 1000
        end
         
        raw.scan(/connections (\d+?) requests (\d+?) replies (\d+?) test-duration (\d+\.\d+?) s/) do |conn,req,rep,time|  
          stats.elapsed_time = time.to_f
          stats.successful = rep.to_i
          stats.failed = conn.to_i - rep.to_i # maybe this should be from the Error line
          stats.transactions = conn.to_i
        end
        
        raw.scan(/Reply size [B]: header (\d+\.\d+?) content (\d+\.\d+?) footer (\d+\.\d+?) .total (\d+\.\d+?)./) do |h,c,f,t|
          stats.data_transferred = ((t.to_f || 0 ) / 1_048_576).to_f # TODO: convert from bytes to MB
        end
        stats.vusers = self.vusers
        
        
        stats
      end



    end
  end
end