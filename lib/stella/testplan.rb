

module Stella
class Testplan
  include Gibbler::Complex
  
  attr_accessor :usecases
  attr_accessor :base_path
  attr_accessor :desc
  
  def initialize
    @desc, @usecases = "Stella's plan", []
    @testplan_current_ratio = 0
  end
  
  def self.load_file(path)
    conf = File.read path
    plan = Stella::Testplan.new
    plan.base_path = File.dirname path
    # eval so the DSL code can be executed in this namespace.
    plan.instance_eval conf
    plan
  end
  
  def check!
    # Adjust ratios if necessary
    needy = @usecases.select do |u| 
      u.ratio < 0 
    end
    needy.each do |u|
      u.ratio = (remaining_ratio / needy.size).to_i
    end
    raise WackyRatio, @testplan_current_ratio if @testplan_current_ratio > 100 
  end
  
  def remaining_ratio
    100 - @testplan_current_ratio
  end
  private :remaining_ratio
  
  def usecase(*args, &blk)
    return @usecases if args.empty?
    ration, name = nil,nil
    ratio, name = args[0], args[1] if args[0].is_a?(Fixnum)
    ratio, name = args[1], args[0] if args[0].is_a?(String)
    uc = Stella::Testplan::Usecase.new
    uc.base_path = @base_path
    uc.instance_eval &blk
    uc.ratio, uc.desc = (ratio || -1).to_i, name
    @testplan_current_ratio += uc.ratio if uc.ratio > 0
    add_usecase uc
  end
  def xusecase(*args, &blk); Stella.ld "Skipping usecase"; end
  
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
    attr_accessor :resources
    attr_accessor :base_path
    
    def initialize(&blk)
      @requests, @resources = [], {}
      instance_eval &blk unless blk.nil?
    end
    
    def desc(*args)
      @desc = args.first unless args.empty?
      @desc
    end
    
    def resource(name, value=nil)
      @resources[name] = value unless value.nil?
      @resources[name]
    end
    
    # Reads the contents of the file <tt>path</tt> (the current working
    # directory is assumed to be the same directory containing the test plan).
    def file(path)
      path = File.join(@base_path, path) if @base_path
      File.read(path)
    end
    
    def list(path)
      file(path).split $/
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
    
    def xget(*args, &blk);    Stella.ld "Skipping get" end
    def xput(*args, &blk);    Stella.ld "Skipping put" end
    def xpost(*args, &blk);   Stella.ld "Skipping post" end
    def xhead(*args, &blk);   Stella.ld "Skipping head" end
    def xdelete(*args, &blk); Stella.ld "Skipping delete" end
    
  end
  
  class WackyRatio < Stella::Error
    def message; "Usecase ratio cannot be higher than 100 (#{@obj})"; end
  end
end
end

__END__
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
