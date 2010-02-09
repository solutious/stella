
module Stella::Engine
  @service = nil
  class << self
    attr_accessor :service
  end
  # See functional.rb
  class Log < Storable
    include Selectable::Object
    field :stamp
    field :uniqueid
    field :clientid
    field :planid
    field :caseid
    field :reqid
    field :httpmethod
    field :httpstatus
    field :uri     
    field :params
    field :headers
    field :response_headers
    field :response_body
  end
  module Base
    extend self
    
    @testrun = nil
    
    @@client_limit = 1000
    
    def update(*args)
      what, *args = args
      if respond_to?("update_#{what}")
        #Stella.ld "OBSERVER UPDATE: #{what}"
        Stella.rescue { self.send("update_#{what}", *args) }
      else
        Stella.ld "NO UPDATE HANDLER FOR: #{what}" 
      end
    end
    
    def runid(plan)
      args = [Stella.sysinfo.hostname, Stella.sysinfo.user]
      args.push Stella::START_TIME, plan
      args.digest
    end
    
    def log_dir(plan, file=nil)
      stamp = Stella::START_TIME.strftime("%Y%m%d-%H-%M-%S")
      stamp <<"-#{plan.digest.shorter}"
      #stamp << "STAMP"
      l = File.join Stella::Config.project_dir, 'log', stamp
      FileUtils.mkdir_p l unless File.exists? l
      l
    end
    
    def log_path(plan, file)
      File.join log_dir(plan), file
    end
    
    def process_options!(plan, opts={})
      opts = {
        :hosts          => [],
        :clients        => 1,
        :duration       => 0,
        :nowait         => false,
        :arrival        => nil,
        :repetitions    => 1
      }.merge! opts
      
      Stella.stdout.info2 " Options: #{opts.inspect}"
      
      opts[:clients] = plan.usecases.size if opts[:clients] < plan.usecases.size
      
      if opts[:clients] > @@client_limit
        Stella.stdout.info2 "Client limit is #{@@client_limit}"
        opts[:clients] = @@client_limit
      end
      
      # Parses 60m -> 3600. See mixins. 
      if opts[:duration].in_seconds.nil?
        raise Stella::WackyDuration, opts[:duration] 
      end
      
      opts[:duration] = opts[:duration].in_seconds
      
      Stella.stdout.info3 " Hosts: " << opts[:hosts].join(', ')
      opts
    end
    
    
    def run; raise; end
    def update_usecase_quit(client_id, msg) raise end
    def update_request_repeat(client_id, counter, total) raise end
    def update_stats(client_id, http_client, usecase, req) raise end
    def update_prepare_request(*args) raise end
    def update_send_request(*args) raise end
    def update_receive_response(*args) raise end
    def update_execute_response_handler(*args) raise end
    def update_error_execute_response_handler(*args) raise end
    def update_request_error(*args) raise end
    def request_unhandled_exception(*args) raise end
    def update_request_fail(*args) raise end
    
  end
  
  autoload :Functional, 'stella/engine/functional'
  autoload :Load, 'stella/engine/loadbase'
  autoload :LoadPackage, 'stella/engine/load_package'
  autoload :LoadCreate, 'stella/engine/load_create'
  autoload :LoadQueue, 'stella/engine/load_queue'
  autoload :LoadEventMachine, 'stella/engine/load_em'
  
  # These timers are interesting from a reporting perspective.
  Benelux.add_counter    Stella::Client, :execute_response_handler
  Benelux.add_timer          HTTPClient, :do_request
  ## These are contained in connect
  #Benelux.add_timer HTTPClient::Session, :create_socket
  #Benelux.add_timer HTTPClient::Session, :create_ssl_socket
  Benelux.add_timer HTTPClient::Session, :connect
  Benelux.add_timer HTTPClient::Session, :query
  Benelux.add_timer HTTPClient::Session, :socket_gets_first_byte
  Benelux.add_timer HTTPClient::Session, :get_body

end

class Stella::Testrun
  attr_reader :samples
  attr_reader :plan
  attr_reader :stats
  attr_reader :events
  def initialize(plan, events)
    @plan, @events = plan, events
    @samples, @stats = nil, nil
    reset
  end
  
  def reset
    @samples = []
    @stats = { :summary => {} }
    @plan.usecases.each do |uc|
      @events.each do |event|
        @stats[:summary][event] = Benelux::Stats::Calculator.new
        @stats[uc.digest] ||= { :summary => {} }
        @stats[uc.digest][:summary][event] = Benelux::Stats::Calculator.new
      end
    end
  end
  
  def add_sample batch, concurrency, tl
    
    opts = {
      :batch => batch, 
      :duration => tl.duration,
      :stamp => Time.now.utc.to_i,
      :concurrency => concurrency
    }
    
    sam = Stella::Testrun::Sample.new opts
    
    @plan.usecases.uniq.each_with_index do |uc,i| 
      sam.stats[uc.digest] ||= { :summary => {} }
      uc.requests.each do |req| 
        sam.stats[uc.digest][req.digest] ||= {}
        filter = [uc.digest_cache, req.digest_cache]
        @events.each_with_index do |event,idx|  # do_request, etc...
          stats = tl.stats.group(event)[filter].merge
          sam.stats[uc.digest][req.digest][event] = stats
          # Tally usecase and total summaries at the same time. 
          @stats[uc.digest][:summary][event] += stats
          @stats[:summary][event] += stats
        end
      end
    end
    
    pp sam
    
    if Stella::Engine.service
      #Stella::Engine.service.testrun_log sls
    end
  end
  
  
  class Sample < Storable
    field :batch
    field :concurrency
    field :stamp
    field :duration
    field :stats => Hash
    def initialize(opts={})
      opts.each_pair do |n,v|
        self.send("#{n}=", v) if has_field? n
      end
      @stats = { :summary => {} }
    end
  end
end
