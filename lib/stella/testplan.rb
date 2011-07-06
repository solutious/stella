

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
  class Testplan < Storable
    include Gibbler::Complex
    include Familia
    include Common::PrivacyMethods
    prefix :testplan
    index :id
    field :id, :class => Gibbler::Digest, :meth => :gibbler
    field :custid             => String
    field :usecases           => Array
    field :desc               => String
    field :privacy            => Boolean
    field :favicon            => String
    field :last_run           => Integer
    field :planid             => Gibbler::Digest
    field :notify => Boolean
    include Familia::Stamps
    sensitive_fields :custid, :privacy, :notify
    # Don't include privacy in the gibbler calculation because it
    # doesn't make sense to have both a public and private testplan.
    gibbler :custid, :usecases
    def init(uri=nil)
      preprocess
      if uri
        req = Stella::RequestTemplate.new :get, Stella.canonical_uri(uri)
        @usecases << Stella::Usecase.new(req) 
      end
    end
    def id 
      @id ||= gibbler
      @id
    end
    alias_method :planid, :id
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
      h = (@hostid.nil? || frozen?) && first_request ? Stella.canonical_host(first_request.uri) : @hostid
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
    def checkup base_uri, opts={}
      opts[:base_uri] = base_uri
      run Stella::Engine::Checkup, opts
    end
    def run engine, opts={}
      testrun = Stella::Testrun.new self, engine.mode, opts
      engine.run testrun
    end
    module ClassMethods
      def usecases
        @usecases ||= []
        @usecases
      end
      def checkup base_uri, opts={}
        Stella::Testplan.plan(self).checkup base_uri, opts
      end
      def run engine, opts={}
        Stella::Testplan.plan(self).run engine, opts
      end
      def testplan
        Stella::Testplan.plan(self)
      end
      # Session objects will extend registered classes.
      def register klass=nil
        unless klass.nil?
          @registered_classes ||= []
          @registered_classes << klass
        end
        @registered_classes
      end
      attr_reader :registered_classes
      def session
        @session ||= {}
        @session
      end
    end
    class << self
      attr_reader :plans
      def inherited obj
        super
        obj.extend ClassMethods
      end
      def from_hash(*args)
        me = super(*args)
        me.usecases.collect! { |uc| Stella::Usecase.from_hash(uc) }
        me
      end
      def plans
        @plans ||= {}
        @plans
      end
      def plan(klass,v=nil)
        # Store the class as a string. Ruby calls Object#hash before setting
        # the hash key which conflicts with Familia::Object.hash.
        plans[klass.to_s] = v unless v.nil?
        plans[klass.to_s]
      rescue NameError => ex
        nil
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
  class Usecase < Storable
    include Gibbler::Complex
    field :id, :class => Gibbler::Digest, :meth => :gibbler
    field :desc             => String
    field :ratio            => Float
    field :requests         => Array
    field :http_auth        => Hash
    field :ucid             => Gibbler::Digest
    gibbler :requests
    def initialize(req=nil)
      preprocess
      @requests << req if req
    end
    def id 
      @id ||= gibbler
      @id
    end
    alias_method :ucid, :id
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
    module ClassMethods
      [:get, :put, :head, :post, :delete].each do |meth|
        define_method meth do |*args,&definition|
          path, opts = *args
          create_request_template meth, path, opts, &definition
        end
      end
      [:xget, :xput, :xhead, :xpost, :xdelete].each do |ignore|
        define_method ignore do |*args|
          Stella.ld " ignoring #{ignore}: #{args.inspect}"
        end
      end
      def http_auth user, pass=nil, domain=nil
        planname, ucname = *names
        uc = Stella::Testplan.plan(planname).usecases.last
        uc.http_auth = { :user => user, :pass => pass, :domain => domain }
        uc.http_auth
      end
      # Session objects will extend registered classes.
      def register klass=nil
        unless klass.nil?
          @registered_classes ||= []
          @registered_classes << klass
        end
        @registered_classes
      end
      attr_reader :registered_classes
      def session
        @session ||= {}
        @session
      end
      private 
      def create_request_template meth, path, opts=nil, &definition
        opts ||= {}
        planname, ucname = *names
        uc = Stella::Testplan.plan(planname).usecases.last
        Stella.ld " (#{uc.class}) define: #{meth} #{path} #{opts if !opts.empty?}"
        rt = RequestTemplate.new meth, path, opts, &definition
        uc.requests << rt
      end
    end
    class << self 
      attr_accessor :instance, :testplan
      # The class syntax uses the session method defined in ClassMethods.
      # This is here for autogenerated usecases and ones loaded from JSON.
      attr_reader :registered_classes, :session
      def from_hash(*args)
        me = super(*args)
        me.requests.collect! { |req| Stella::RequestTemplate.from_hash(req) }
        me
      end
      def checkup base_uri, opts={}
        (opts[:usecases] ||= []) << self
        testplan.checkup base_uri, opts
      end
      def names
        names = self.to_s.split('::')
        planname, ucname = case names.size
        when 1 then ['DefaultTestplan', names.last]
        else        [names[0..-2].join('::'), names[-1]] end
        [eval(planname), ucname.to_sym]
      end
      def inherited(obj)
        super
        planclass, ucname = *obj.names
        planclass.extend Stella::Testplan::ClassMethods
        unless Stella::Testplan.plan? planclass
          Stella::Testplan.plan(planclass, planclass.new)
          Stella::Testplan.plan(planclass).desc = planclass
        end
        
        obj.instance = obj.new
        obj.testplan = Stella::Testplan.plan(planclass)
        Stella::Testplan.plan(planclass).usecases << obj.instance
        Stella::Testplan.plan(planclass).usecases.last.desc = ucname
        obj.extend ClassMethods
      end
    end
  end
    
  class EventTemplate < Storable
    include Gibbler::Complex
    def id 
      @id ||= gibbler
      @id
    end
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
    field :id, :class => Gibbler::Digest, :meth => :gibbler
    field :protocol         => Symbol
    field :http_method
    field :http_version
    field :http_auth
    field :uri              => String do |v| v.to_s end
    field :params           => Hash
    field :headers          => Hash
    field :body
    field :desc
    field :rtid             => Gibbler::Digest
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
  class Testrun < Storable
    include Gibbler::Complex
    include Familia
    prefix :testrun
    index :id
    include Familia::Stamps
    include Common::PrivacyMethods
    field :id, :class => Gibbler::Digest, :meth => :gibbler
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
    field :runid              => Gibbler::Digest
    field :hostid
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
    def id 
      @id ||= gibbler
      @id
    end
    alias_method :runid, :id
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
      if @plan
        @planid = @plan.id 
        @hostid = @plan.hostid
      end
      @options ||= {}
      @privacy ||= false
    end
    def postprocess
      @id &&= Gibbler::Digest.new(@id)
      # Calling plan calls Redis. 
      #@privacy = plan.privacy if Stella::Testplan === plan
      if Hash === @report
        @report = Stella::Report.from_hash @report
        @report.runid = runid
      end
      @planid &&= Gibbler::Digest.new(@planid)
    end
    def hostid
      # NOTE: This method is needed only until May 30 or so.
      # (there was an issue where incidents were not including a hostid)
      @hostid || (plan.nil? ? nil : plan.hostid)
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
        #@plan.freeze
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
class DefaultTestplan < Stella::Testplan; end
