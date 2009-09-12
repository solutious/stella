

module Stella
class Testplan
  attr_accessor :usecases
  attr_accessor :desc
  
  def initialize
    @desc, @usecases = "Stella's plan", []
  end
  
  def self.load_file(path)
    conf = File.read path
    plan = Stella::Testplan.new
    # eval so the DSL code can be executed in this namespace.
    plan.instance_eval conf
    plan
  end
  
  def usecase(*args, &blk)
    return @usecases if args.empty?
    uc = Stella::Testplan::Usecase.new(&blk)
    add_usecase uc
  end
  
  def add_usecase(uc)
    Stella.ld "Usecase: #{uc.desc}"
    @usecases << uc
    uc
  end
  
  def desc(*args)
    @desc = args.first unless args.empty?
    @desc
  end

  def to_s
    ucstr = []
    @usecases.each_with_index do |uc,i| 
      description = uc.desc || "usecase#{i+1}"
      requests = uc.requests.collect { |r| r.uri.to_s }
      ucstr << "%s(%s)" % [description, requests.join(', ')]
    end
    "%s: %s" % [@desc, ucstr.join('; ')]
  end
  
  class Usecase
    attr_accessor :requests
    
    def initialize(&blk)
      @requests = []
      instance_eval &blk unless blk.nil?
    end
    
    def desc(*args)
      @desc = args.first unless args.empty?
      @desc
    end
    
    def get(*args, &blk)
      add_request :get, *args, &blk
    end
    
    def post(*args, &blk)
      add_request :post, *args, &blk
    end
    
    def add_request(meth, *args, &blk)
      req = Stella::Data::HTTP::Request.new meth.to_s.upcase, args.first, &blk
      Stella.ld req
      @requests << req
    end
    
  end
  
end
end

# instance_exec for Ruby 1.8 written by Mauricio Fernandez
# http://eigenclass.org/hiki/instance_exec
if RUBY_VERSION =~ /1.8/
  module InstanceExecHelper; end
  include InstanceExecHelper
  def instance_exec(*args, &block) # !> method redefined; discarding old instance_exec
    mname = "__instance_exec_#{Thread.current.object_id.abs}_#{object_id.abs}"
    InstanceExecHelper.module_eval{ define_method(mname, &block) }
    begin
      ret = send(mname, *args)
    ensure
      InstanceExecHelper.module_eval{ undef_method(mname) } rescue nil
    end
    ret
  end
end
