

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
    include Common::PrivacyMethods
    field :id                 => Gibbler::Digest, &gibbler_id_processor
    field :userid             => String
    field :usecases           => Array
    field :desc               => String
    field :privacy            => Boolean
    field :favicon            => String
    field :last_run           => Integer
    # Don't include provacy in the gibbler calculation because it
    # doesn't make sense to have both a public and private testplan.
    gibbler :userid, :usecases
    def initialize(uri=nil)
      preprocess
      if uri
        req = Stella::TP::RequestTemplate.new :get, uri
        @usecases << Stella::TP::Usecase.new(req) 
      end
    end
    def favicon?() !@favicon.nil? && !@favicon.empty? end
    def preprocess
      @usecases ||= []
      @privacy = false if @privacy.nil?
    end
    def postprocess
      @id = Gibbler::Digest.new(@id) if String === @id
    end
    def first_request
      return if @usecases.empty?
      @usecases.first.requests.first
    end
    def freeze
      return if frozen?
      @usecases.each { |uc| uc.freeze }
      @id ||= self.digest
      super
      self
    end
    def self.from_hash(*args)
      me = super(*args)
      me.usecases.collect! { |uc| Stella::Testplan::Usecase.from_hash(uc) }
      me
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
      def freeze
        return if frozen?
        @requests.each { |r| r.freeze }
        @id ||= self.digest
        super
        self
      end
      def self.from_hash(*args)
        me = super(*args)
        me.requests.collect! { |req| Stella::Testplan::RequestTemplate.from_hash(req) }
        me
      end
    end
    
    class EventTemplate < StellaObject
    end
    
    class RequestTemplate < EventTemplate
      field :id               => Gibbler::Digest, &gibbler_id_processor
      field :protocol         => Symbol
      field :http_method
      field :http_version
      field :http_auth
      field :uri
      field :params           => Array
      field :headers          => Array
      field :body
      field :desc
      field :wait             => Range
      field :response_handler => Hash
      gibbler :http_method, :uri, :http_version, :params, :headers, :body
      def initialize(meth=nil, uri=nil)
        @protocol = :http
        @http_method, @uri = meth, uri
      end
      def freeze
        return if frozen?
        self.id ||= self.digest
        super
        self
      end
    end
    
    UC = Usecase
    RT = RequestTemplate
  end
  TP = Testplan
end



class Stella
  class Testrun < StellaObject
    include Common::PrivacyMethods
    field :id                 => Gibbler::Digest, &gibbler_id_processor
    field :userid             => String
    field :status             => Symbol
    field :options            => Hash
    field :mode               => Symbol
    field :hosts
    field :start_time         => Integer
    field :end_time           => Integer
    field :salt
    field :planid             => Gibbler::Digest
    field :privacy            => Boolean
    gibbler :salt, :planid, :userid, :hosts, :mode, :options, :start_time
    attr_reader :plan
    def initialize plan=nil, options={}
      @plan = plan
      @options = {
      }.merge options
      preprocess
    end
    def preprocess
      @salt ||= Stella.now.digest.short
      @status ||= :new
      @planid = @plan.id if @plan
      @options ||= {}
    end
    def run mode=nil
      @mode = mode unless mode.nil?
      raise StellaError.new("No mode") unless Stella::Engine.mode?(@mode)
      engine = Stella::Engine.load(@mode)
      engine.run @run
    end
    def start_time!
      @start_time = Stella.now
    end
    def end_time!
      @end_time = Stella.now
    end
    class << self
      attr_reader :statuses
    end
    @statuses = [:new, :pending, :running, :done, :failed, :cancelled]
    @statuses.each do |status|
      define_method :"#{status}?" do
        @status == status
      end
      define_method :"#{status}!" do
        @status = status
        save if respond_to? :save
      end
    end
  end
end
