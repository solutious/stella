
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
  class Base
    
    class << self
      attr_accessor :timers, :counts
    end
    
    attr_reader :testrun, :logdir, :opts
    
    def initialize(opts={})
      @opts = opts
      @logdir = nil
    end
    
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
      args.id
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
  autoload :Load, 'stella/engine/load'
  
  # These timers are interesting from a reporting perspective.
  Benelux.add_counter    Stella::Client, :execute_response_handler
  Benelux.add_timer          HTTPClient, :do_request, :response_time
  ## These are contained in connect
  #Benelux.add_timer HTTPClient::Session, :create_socket
  #Benelux.add_timer HTTPClient::Session, :create_ssl_socket
  Benelux.add_timer HTTPClient::Session, :connect, :socket_connect
  Benelux.add_timer HTTPClient::Session, :query, :send_request
  Benelux.add_timer HTTPClient::Session, :socket_gets_first_byte, :first_byte
  Benelux.add_timer HTTPClient::Session, :get_body, :receive_response

end

class Stella::Testrun < Storable
  CLIENT_LIMIT = 1000
  include Gibbler::Complex
  field :id => String, &gibbler_id_processor
  field :status => String
  field :userid => String
  field :start_time => Integer
  field :clients => Integer
  field :duration => Integer
  field :arrival => Float
  field :repetitions => Integer
  field :wait => Float
  field :nowait => TrueClass
  field :withparam => TrueClass
  field :withheader => TrueClass
  field :notemplates => TrueClass
  field :nostats => TrueClass
  field :stats => Hash
  field :samples => Array
  field :mode  # verify or generate
  field :plan
  field :hosts
  field :events
  field :log
  gibbler :plan, :hosts, :mode, :clients, :duration, :repetitions, :wait, :start_time, :userid
  def initialize(plan=nil, opts={})
    @plan = plan
    process_options! opts if !plan.nil? && !opts.empty?
    reset_stats
  end
  def id
    @id || self.digest
  end
  def self.from_hash(hash={})
    me = super(hash)
    me.plan = Stella::Testplan.from_hash(me.plan)
    me.process_options! unless me.plan.nil?
    
    me.samples.collect! do |sample|
      Stella::Testrun::Sample.from_hash(sample)
    end

    me.plan.usecases.uniq.each_with_index do |uc,i| 
      uc.requests.each do |req| 
        me.events.each_with_index do |event,idx|  # do_request, etc...
          event &&= event.to_s
          me.stats[uc.id][req.id][event] = 
            Benelux::Stats::Calculator.from_hash(me.stats[uc.id][req.id][event])
          me.stats[uc.id]['summary'][event] = 
            Benelux::Stats::Calculator.from_hash(me.stats[uc.id]['summary'][event])
          me.stats['summary'][event] = 
            Benelux::Stats::Calculator.from_hash(me.stats['summary'][event])
        end
      end
    end
    
    me
  end
  
  def client_options
    opts = {
      :nowait => self.nowait || false,
      :notemplates => self.notemplates || false,
      :withparam => self.withparam || false,
      :withheader => self.withheader || false,
      :wait => self.wait || 0
    }
  end
  
  def process_options!(opts={})
    
    unless opts.empty?
      opts = {
        :hosts          => [],
        :clients        => 1,
        :duration       => 0,
        :wait           => 0,
        :nowait         => false,
        :arrival        => nil,
        :repetitions    => 1, 
        :mode           => :verify
      }.merge! opts      

      opts.each_pair do |n,v|
        self.send("#{n}=", v) if has_field? n
      end
      
      Stella.ld " Options: #{opts.inspect}"
    end
    
    @id &&= Gibbler::Digest.new(@id)
    
    @samples ||= []
    @stats ||= { :summary => {} }
    
    @status ||= "new"
    @events ||= [:response_time, :failed]
    
    @start_time ||= Time.now.to_i
    
    @events.collect! { |event| event.to_sym }
    
    @duration ||= 0
    @repetitions ||= 0
    
    @clients &&= @clients.to_i
    @duration &&= @duration.to_i
    @arrival &&= @arrival.to_f
    @repetitions &&= @repetitions.to_i
    @wait &&= @wait.to_f
    
    @mode &&= @mode.to_sym
    
    @hosts = [@hosts] unless Array === @hosts
    
    @hosts.collect! do |host|
      host.to_s
    end
    
    if @clients > CLIENT_LIMIT
      Stella.stdout.info2 "Client limit is #{CLIENT_LIMIT}"
      @clients = CLIENT_LIMIT
    end
    
    # Parses 60m -> 3600. See mixins. 
    @duration = @duration.in_seconds
    
    raise Stella::WackyDuration, @duration if @duration.nil?
    
    @mode &&= @mode.to_sym
    
    unless [:verify, :generate].member?(@mode)
      raise Stella::Error, "Unsupported mode: #{@mode}"
    end
    
    if Hash === self.plan # When reconstituting from JSON
      self.plan = Stella::Testplan.from_hash(self.plan)
    end
    
    if Stella::Testplan === self.plan
      # Plan must be frozen before running (see freeze methods)
      self.plan.frozen? || self.plan.freeze  
      @clients = plan.usecases.size if @clients < plan.usecases.size
    end
    
    @id ||= self.gibbler # populate id
    
  end
  
  def freeze
    return if frozen?
    Stella.ld "FREEZE TESTRUN: #{self.id}"
    plan.freeze
    super
    self
  end
  
  def log_dir
    # Don't use @start_time here b/c that won't be set 
    # until just before the actual testing starts. 
    stamp = Stella::START_TIME.strftime("%Y%m%d-%H-%M-%S")
    stamp << "-#{self.plan.id.shorter}" unless self.plan.nil?
    l = File.join Stella::Config.project_dir, 'log', stamp
    FileUtils.mkdir_p l unless File.exists?(l) || Stella::Logger.disabled?
    l
  end
  
  def log_path(file)
    File.join log_dir, file
  end
  
  
  def run(opts={})
    engine = case self.mode 
    when :verify 
      Stella::Engine::Functional.new(opts)
    when :generate
      Stella::Engine::Load.new(opts)
    else
      raise Stella::Error, "Unsupported mode: #{self.mode}"
    end
    engine.run self
    @status = "done"
    self.freeze
    self
  end
  
  def save
    unless Stella::Logger.disabled?
      path = log_path('stats')
      Stella::Utils.write_to_file(path, self.to_json, 'w', 0644) 
    end
  end
  
  def reset_stats
    @samples = []
    @stats = { 'summary' => {} }
    unless @plan.nil?
      @plan.usecases.each do |uc|
        @events.each do |event|
          event &&= event.to_s
          @stats['summary'][event] = Benelux::Stats::Calculator.new
          @stats[uc.id] ||= { 'summary' => {} }
          @stats[uc.id]['summary'][event] = Benelux::Stats::Calculator.new
          uc.requests.each do |req|
            @stats[uc.id][req.id] ||= {}
            @stats[uc.id][req.id][event] = Benelux::Stats::Calculator.new
          end
        end
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
      sam.stats[uc.id] ||= { }
      uc.requests.each do |req| 
        sam.stats[uc.id][req.id] ||= {}
        filter = [uc.id, req.id]
        @events.each_with_index do |event,idx|  # do_request, etc...
          event &&= event.to_s
          stats = tl.stats.group(event.to_sym)[filter].merge
          sam.stats[uc.id][req.id][event] = stats
          # Tally request, usecase and total summaries at the same time. 
          @stats[uc.id][req.id][event] += stats
          @stats[uc.id]['summary'][event] += stats
          @stats['summary'][event] += stats
        end
      end
    end
    
    @samples << sam
    
    sam
  end
  
  
  class Sample < Storable
    field :batch
    field :concurrency
    field :stamp
    field :duration
    field :stats => Hash
    #gibbler :batch, :concurrency, :stamp, :duration
    def initialize(opts={})
      opts.each_pair do |n,v|
        self.send("#{n}=", v) if has_field? n
      end
      @stats = { }
    end
    def self.from_hash(hash={})
      me = super(hash)
      stats = {}
      me.stats.each_pair { |ucid,uchash| 
        stats[ucid] = {}
        uchash.each_pair { |reqid,reqhash|
          stats[ucid][reqid] = {}
          reqhash.each_pair { |event,stat|
            tmp = Benelux::Stats::Calculator.from_hash(stat)
            stats[ucid][reqid][event] = tmp
          }
        }
      }
      me.stats = stats
      me
    end
  end
end
