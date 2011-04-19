

class Stella
  module Common
    module PrivacyMethods
      def private?
        privacy == true
      end
      def public?
        !private?
      end
      def private!
        @privacy = true
      end
      def public!
        @privacy = false
      end
    end
  end
  class Testplan < StellaObject
    include Familia
    include Common::PrivacyMethods
    prefix :testplan
    index :id
    field :id                 => Gibbler::Digest, &gibbler_id_processor
    field :custid             => String
    field :usecases           => Array
    field :desc               => String
    field :privacy            => Boolean
    field :favicon            => String
    field :last_run           => Integer
    field :notify => Boolean
    include Familia::Stamps
    sensitive_fields :custid, :privacy, :notify
    # Don't include provacy in the gibbler calculation because it
    # doesn't make sense to have both a public and private testplan.
    gibbler :custid, :usecases
    def init(uri=nil)
      preprocess
      if uri
        req = Stella::RequestTemplate.new :get, Stella.canonical_uri(uri)
        @usecases << Stella::Usecase.new(req) 
      end
    end
    def favicon?() !@favicon.nil? && !@favicon.empty? end
    def preprocess
      @usecases ||= []
      @privacy = false if @privacy.nil?
    end
    def first_request
      return if @usecases.empty?
      @usecases.first.requests.first
    end
    def freeze
      return if frozen?
      @usecases.each { |uc| uc.freeze }
      @id &&= Gibbler::Digest.new(@id || self.digest)
      super
      self
    end
    def postprocess
      @id &&= Gibbler::Digest.new(@id)
      @notify ||= false 
      @notify &&= false if @notify == 'false'
    end
    def cust
      @cust ||= Customer.from_redis @custid
      @cust || Customer.anonymous
    end
    def monitor
      MonitorInfo.from_redis @id
    end
    def monitored?
      mon = monitor
      mon && mon.enabled
    end
    def host
      h = @host.nil? || frozen? ? HostInfo.load_or_create(hostid) : @host
      frozen? ? h : (@host=h)
    end
    def hostid
      h = @hostid.nil? || frozen? ? Stella.canonical_host(first_request.uri) : @hostid
      frozen? ? h : (@hostid=h)
    end
    def destroy!
      raise BS::Problem, "Monitor exists #{index}" if MonitorInfo.exists?(index)
      host.testplans.rem self unless host.nil?
      cust.testplans.rem self unless cust.nil?
      super
    end
    def owner?(guess)
      custid != nil && cust.custid?(guess)
    end
    class << self
      attr_reader :plans
      def from_hash(*args)
        me = super(*args)
        me.usecases.collect! { |uc| Stella::Usecase.from_hash(uc) }
        me
      end
      def plans
        @plans ||= {}
        @plans
      end
      def plan(name)
        plans[name]
      end
      def plan?(name)
        !plan(name).nil?
      end
      def global?(name)
        global.has_key?(name)
      end
      def global
        @global ||= {}
        @global
      end
    end
  end
  class Usecase < StellaObject
    field :id               => Gibbler::Digest, &gibbler_id_processor
    field :desc             => String
    field :ratio            => Float
    field :requests         => Array
    gibbler :requests
    def initialize(req=nil)
      preprocess
      @requests << req if req
    end
    def preprocess
      @requests ||= []
    end
    def postprocess
      @id &&= Gibbler::Digest.new(@id)
    end
    def freeze
      return if frozen?
      @requests.each { |r| r.freeze }
      @id &&= Gibbler::Digest.new(@id || self.digest)
      super
      self
    end
    class << self 
      attr_accessor :instance
      def from_hash(*args)
        me = super(*args)
        me.requests.collect! { |req| Stella::RequestTemplate.from_hash(req) }
        me
      end
      def names
        names = self.to_s.split('::')
        planname, ucname = case names.size
        when 1 then [:default, names.last]
        else        [names[0..-2].join('::'), names[-1]] end
        [eval(planname), ucname.to_sym]
      end
      def inherited(obj)
        planclass, ucname = *obj.names
        planclass.module_eval do
          class << self
            def usecases
              @usecases ||= []
              @usecases
            end
            def checkup(base_uri, opts={})
              opts[:base_uri] = base_uri
              run Stella::Engine::Checkup, opts
            end
            def run(engine, opts={})
              testrun = Stella::Testrun.new Stella::Testplan.plans[self], engine.mode, opts
              report = engine.run testrun
            end
          end
        end
        unless Stella::Testplan.plan? planclass
          Stella::Testplan.plans[planclass] = Stella::Testplan.new
          Stella::Testplan.plans[planclass].desc = planclass
        end
        obj.instance = Stella::Usecase.new
        Stella::Testplan.plans[planclass].usecases << obj.instance
        Stella::Testplan.plans[planclass].usecases.last.desc = ucname
      end
      [:get, :put, :head, :post, :delete].each do |meth|
        define_method meth do |*args,&definition|
          path, opts = *args
          create_request_template meth, path, opts, &definition
        end
      end
      [:xget, :xput, :xhead, :xpost, :xdelete].each do |ignore|
        define_method ignore do |*args|
        end
      end
      private 
      def create_request_template meth, path, opts, &definition
        planname, ucname = names
        uc = Stella::Testplan.plans[planname].usecases.last
        Stella.ld " (#{uc.class}) define: #{meth} #{path} #{opts if !opts.empty?}"
        req = RequestTemplate.new meth, path, opts, &definition
        uc.requests << req
      end
    end
  end
    
  class EventTemplate < StellaObject
  end
  
  class StringTemplate
    include Gibbler::String
    attr_reader :src
    def initialize(src)
      src = src.to_s
      @src, @template = src, ERB.new(src)
    end
    def result(binding)
      @template.result(binding)
    end
    def to_s() src end
  end
  
  class RequestTemplate < EventTemplate
    field :id               => Gibbler::Digest, &gibbler_id_processor
    field :protocol         => Symbol
    field :http_method
    field :http_version
    field :http_auth
    field :uri              => String do |v| v.to_s end
    field :params           => Hash
    field :headers          => Hash
    field :body
    field :desc
    field :wait             => Range
    field :response_handler => Hash, &hash_proc_processor
    field :follow           => Boolean
    attr_accessor :callback
    gibbler :http_method, :uri, :http_version, :params, :headers, :body
    def initialize(meth=nil, uri=nil, opts={}, &definition)
      @protocol = :http
      @http_method, @uri = meth, uri
      opts.each_pair { |n,v| self.send("#{n}=", v) if self.class.has_field?(n) }
      @params ||= {}
      @headers ||= {}
      @follow ||= false
      @callback = definition
    end
    def postprocess
      @id &&= Gibbler::Digest.new(@id)
      unless response_handler.nil?
        response_handler.keys.each do |range|
          proc = response_handler[range]
          response_handler[range] = Proc.from_string(proc) if proc.kind_of?(ProcString)
        end
      end
    end
    def freeze
      return if frozen?
      @id &&= Gibbler::Digest.new(@id || self.digest)
      super
      self
    end
    alias_method :param, :params
    alias_method :header, :headers
  end
    
  TP = Testplan
  UC = Usecase
  RT = RequestTemplate
  ET = EventTemplate
  
end



class Stella
  class Testrun < StellaObject
    include Familia
    prefix :testrun
    index :id
    include Familia::Stamps
    include Common::PrivacyMethods
    field :id                 => Gibbler::Digest, &gibbler_id_processor
    field :custid             => String
    field :status             => Symbol
    field :options            => Hash
    field :mode               => Symbol
    field :hosts
    field :ctime              => Float
    field :stime              => Float
    field :etime              => Float
    field :salt
    field :planid             => Gibbler::Digest
    field :privacy            => Boolean
    field :report             => Stella::Report
    sensitive_fields :custid, :salt, :privacy
    gibbler :salt, :planid, :custid, :hosts, :mode, :options, :ctime
    attr_reader :plan
    alias_method :start_time, :stime
    alias_method :end_time, :etime
    def init plan=nil, mode=nil, options={}
      @ctime = Stella.now
      @plan, @mode = plan, mode
      @options = {
      }.merge options
      preprocess
    end
    def duration
      return 0 unless @stime
      (@etime || Stella.now) - @stime
    end
    def errors?
      @report && @report.errors?
    end
    def preprocess
      @salt ||= Stella.now.digest.short
      @status ||= :new
      @planid = @plan.id if @plan
      @options ||= {}
      @privacy ||= false
    end
    def postprocess
      @id &&= Gibbler::Digest.new(@id)
      @privacy = plan.privacy if Stella::Testplan === plan
      @report = Stella::Report.from_hash @report if Hash === @report
      @planid &&= Gibbler::Digest.new(@planid)
    end
    def run opts={}
      raise StellaError.new("No mode") unless Stella::Engine.mode?(@mode)
      engine = Stella::Engine.load(@mode)
      opts.merge! @options
      engine.run self, opts
      save if respond_to? :save
      self.report
    end
    def checkup?
      @mode == :checkup
    end
    def monitor?
      @mode == :monitor
    end
    def destroy!
      VendorInfo.global.checkups.remove self
      host.checkups.remove self if host
      plan.checkups.remove self if plan
      cust.checkups.remove self if cust
      super
    end
    def plan
      if @plan.nil? 
        @plan = Stella::Testplan.from_redis @planid
        @plan.freeze
      end
      @plan
    end
    def owner?(obj)
      obj = Customer === obj ? obj.custid : obj
      cust.username?(obj)
    end
    def cust
      @cust ||= Customer.from_redis @custid
      @cust || Customer.anonymous
    end
    def host
      @host ||= plan.host if plan
      @host
    end
    class << self
      attr_reader :statuses
    end
    @statuses = [:new, :pending, :running, :done, :failed, :fubar, :cancelled]
    @statuses.each do |status|
      define_method :"#{status}?" do
        @status == status
      end
      define_method :"#{status}!" do
        @status = status
        begin
          save if respond_to? :save
        rescue Errno::ECONNREFUSED => ex
          Stella.ld ex.message
        end
      end
    end
  end
end
