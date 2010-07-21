STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__) unless defined?(STELLA_LIB_HOME)

%w{tryouts storable gibbler}.each do |dir|
  $:.unshift File.join(STELLA_LIB_HOME, '..', '..', dir, 'lib')
end

require 'storable'
require 'gibbler/aliases'

class StellaObject < Storable
  include Gibbler::Complex
  def id
    @id ||= self.digest
    @id
  end
end

class StellaError < RuntimeError
end

class Stella
  require 'stella/testplan'
  
  attr_reader :plan
  def initialize *args
    @plan = Stella::TP === args.first ? 
      args.first.clone : Stella::TP.new(args.first)
    @plan.freeze
    @runner
  end
  
end 

class Stella
  module Engine
    @modes = {}
    class << self
      attr_reader :modes
      def mode?(name)
        @mode.has_key? name
      end
      def load(name)
        @modes[name]
      end
    end
    module Base
      def self.included(obj)
        obj.extend ClassMethods
      end
      module ClassMethods
        def register(mode)
          @mode = mode
          Stella::Engine.modes[mode] = self
        end
        attr_reader :mode
      end
    end
    module Checkup
      include Engine::Base
      register :checkup
    end
  end
end

class Stella
  class Testrun < StellaObject
    field :id                 => Gibbler::Digest, &gibbler_id_processor
    field :userid => String
    field :status => Symbol
    field :client_opts => Hash
    field :engine_opts => Hash
    field :mode => Symbol
    field :hosts
    field :time_start => Integer
    field :time_end => Integer
    field :salt
    field :planid
    gibbler :salt, :planid, :userid, :hosts, :mode, :client_opts, :engine_opts, :start_time
    attr_reader :plan
    def initialize plan=nil, client_opts={}, engine_opts={}
      @plan = plan
      @client_opts, @engine_opts = client_opts, engine_opts
      preprocess
    end
    def preprocess
      @salt ||= rand.digest.short
      @status ||= :new
      @planid = @plan.id if @plan
    end
    def freeze
      @id ||= self.digest
      super
    end
    @statuses = [:new, :pending, :running, :done, :failed, :cancelled]
    class << self
      attr_reader :statuses
    end
    @statuses.each do |status|
      define_method :"#{status}?" do
        @status == status
      end
      define_method :"#{status}!" do
        @status = status
      end
    end
  end
end


class Stella
  # static methods
  class << self
    def get(uri)
      uri
    end
    def checkup(uri)
      tplan = Stella::Testplan.new uri
      uri
    end
  end
end
