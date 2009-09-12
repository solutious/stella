

module Stella
class Testplan
  attr_accessor :usecases
  
  def initialize
    @usecases = []
  end
  
  def self.load_file(path)
    conf = File.read path
    plan = Stella::Testplan.new
    # eval so the DSL code can be executed in this namespace.
    plan.instance_eval conf
  end
  
  def usecase(*args, &blk)
    
    @usecases << Stella::Testplan::Usecase.new(&blk)
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
    
    private
    
    def add_request(meth, *args, &blk)
      req = Stella::Data::HTTP::Request.new args.first, 'GET', &blk
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
