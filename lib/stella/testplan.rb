

module Stella
class Testplan
  include Gibbler::Complex
  
  attr_accessor :usecases
  attr_accessor :desc
  
  def initialize
    @desc, @usecases = "Stella's plan", []
    @testplan_current_ratio = 0
  end
  
  def self.load_file(path)
    conf = File.read path
    plan = Stella::Testplan.new
    # eval so the DSL code can be executed in this namespace.
    plan.instance_eval conf
    plan
  end
  
  def check!
    raise WackyRatio, @testplan_current_ratio if @testplan_current_ratio > 100 
  end
  
  def usecase(*args, &blk)
    return @usecases if args.empty?
    uc = Stella::Testplan::Usecase.new(&blk)
    uc.ratio, uc.desc = (args[0] || 100).to_i, args[1]
    @testplan_current_ratio += uc.ratio
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

  def pretty
    str = []
    str << " %-50s ".att(:reverse) % [@desc]
    @usecases.each_with_index do |uc,i| 
      description = uc.desc || "Usecase ##{i+1}"
      str << "  %s (%s)".bright % [description, uc.ratio]
      requests = uc.requests.each do |r| 
        str << "    %-35s %s" % ["#{r.desc}:", r]
        if Stella.loglev > 2
          [:wait].each { |i| str << "      %s: %s" % [i, r.send(i)] }
        end
      end
    end
    str.join($/)
  end
  
  class Usecase
    include Gibbler::Complex
    attr_accessor :desc
    attr_accessor :requests
    attr_accessor :ratio
    
    def initialize(&blk)
      @requests = []
      instance_eval &blk unless blk.nil?
    end
    
    def desc(*args)
      @desc = args.first unless args.empty?
      @desc
    end
    
    def add_request(meth, *args, &blk)
      req = Stella::Data::HTTP::Request.new meth.to_s.upcase, args[0], &blk
      req.desc = args[1] if args.size > 1 # Description is optional
      Stella.ld req
      @requests << req
    end
    def get(*args, &blk);    add_request :get,    *args, &blk; end
    def put(*args, &blk);    add_request :put,    *args, &blk; end
    def post(*args, &blk);   add_request :post,   *args, &blk; end
    def head(*args, &blk);   add_request :head,   *args, &blk; end
    def delete(*args, &blk); add_request :delete, *args, &blk; end
    
  end
  
  class WackyRatio < Stella::Error
    def message; "Usecase ratio cannot be higher than 100 (#{@obj})"; end
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
