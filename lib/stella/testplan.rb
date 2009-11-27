autoload :CSV, 'csv'
#Gibbler.enable_debug

module Stella
class Testplan < Storable
  include Gibbler::Complex
  extend Attic
  
  @file_cache = {}
  
  class << self
    attr_reader :file_cache
    def readlines path
      if @file_cache.has_key?(path)
        Stella.ld "FILE CACHE HIT: #{path}"
        return @file_cache[path]
      end
      Stella.ld "FILE CACHE LOAD: #{path}"
      @file_cache[path] = File.readlines(path)
    end
  end
  
  attic :base_path
  attic :plan_path
  attic :description
  
  field :id do |val|
    self.gibbler
  end
  field :usecases 
  field :description 
  
  def initialize(uris=[], opts={})
    self.description = "Test plan"
    @usecases = []
    @testplan_current_ratio = 0
    @stats = Stella::Testplan::Stats.new

    unless uris.empty?
      uris = [uris] unless Array === uris
      usecase = Stella::Testplan::Usecase.new
      usecase.ratio = 1.0
      uris.each do |uri|
        uri = 'http://' << uri unless uri.match /^http:\/\//i
        uri = URI.parse uri
        uri.path = '/' if uri.path.nil? || uri.path.empty?
        req = usecase.add_request :get, uri.path
        req.wait = opts[:wait] if opts[:wait]
      end
      self.add_usecase usecase
    end
  end
  
  def self.load_file(path)
    conf = File.read path
    plan = Stella::Testplan.new
    plan.base_path = File.dirname path
    plan.plan_path = path
    # eval so the DSL code can be executed in this namespace.
    plan.instance_eval conf, path 
    plan
  end
  
  def check!
    # Adjust ratios if necessary
    needy = @usecases.select { |u| u.ratio == -1 }
    needy.each do |u|
      u.ratio = (remaining_ratio / needy.size).to_f
    end
    if @testplan_current_ratio > 1.0 
      msg = "Usecase ratio cannot be higher than 1.0"
      msg << " (#{@testplan_current_ratio})"
      raise Stella::WackyRatio, msg
    end
  end
  
  # make sure all clients share identical test plans
  def freeze
    Stella.ld "FREEZE TESTPLAN: #{self.description}"
    @usecases.each { |uc| uc.freeze }
    super
    self
  end
  
  def usecase(*args, &blk)
    return @usecases if args.empty? && blk.nil?
    ratio, name = nil,nil
    unless args.empty?
      ratio, name = args[0], args[1] if args[0].is_a?(Numeric)
      ratio, name = args[1], args[0] if args[0].is_a?(String)
    end
    uc = Stella::Testplan::Usecase.new
    uc.base_path = self.base_path
    uc.plan_path = self.plan_path
    uc.instance_eval &blk
    uc.ratio = (ratio || -1).to_f
    uc.description = name unless name.nil?
    @testplan_current_ratio += uc.ratio if uc.ratio > 0
    add_usecase uc
  end
  def xusecase(*args, &blk); Stella.ld "Skipping usecase"; end
  
  def add_usecase(uc)
    Stella.ld "Usecase: #{uc.description}"
    @usecases << uc
    uc
  end
  
  # for DSL use-only (otherwise use: self.description)
  def desc(*args)
    self.description = args.first unless args.empty?
    self.description
  end

    
    
  def pretty(long=false)
    str = []
    dig = long ? self.digest_cache : self.digest_cache.shorter
    str << " %-66s  ".att(:reverse) % ["#{self.description}  (#{dig})"]
    @usecases.each_with_index do |uc,i| 
      dig = long ? uc.digest_cache : uc.digest_cache.shorter
      desc = uc.description || "Usecase ##{i+1}"
      desc += "  (#{dig}) "
      str << (' ' << " %-61s %s%% ".att(:reverse).bright) % [desc, uc.ratio_pretty]
      unless uc.http_auth.nil?
        str << '    Auth: %s (%s/%s)' % uc.http_auth.values
      end
      requests = uc.requests.each do |r| 
        dig = long ? r.digest_cache : r.digest_cache.shorter
        str << "    %-62s".bright % ["#{r.description}  (#{dig})"]
        str << "      %s" % [r]
        if Stella.stdout.lev > 1
          [:wait].each { |i| str << "      %s: %s" % [i, r.send(i)] }
          str << '       %s: %s' % ['params', r.params.inspect] 
          r.response_handler.each do |status,proc|
            str << "      response: %s%s" % [status, proc.source.split($/).join("#{$/}    ")]
          end
        end
      end
    end
    str.join($/)
  end
  
  private
  def remaining_ratio
    1.0 - @testplan_current_ratio
  end
  
end
end  
  
  
module Stella
class Testplan

  #
  # Any valid Ruby syntax will do the trick:
  #
  #     usecase(10, "Self-serve") {
  #       post("/listing/add", "Add a listing") {
  #         wait 1..4 
  #         param :name => random(8)
  #         param :city => "Vancouver"
  #         response(302) {
  #           repeat 3
  #         }
  #       }
  #     }
  #
  class Usecase < Storable
    include Gibbler::Complex
    include Stella::Data::Helpers
    extend Attic
    
    class Auth < Struct.new(:kind, :user, :pass)
      include Gibbler::Complex
    end
    
    attic :base_path # we don't want gibbler to see this
    attic :plan_path
    attic :description
    
    field :id do |val|
      self.gibbler
    end
    field :description
    field :ratio
    field :http_auth
    
    field :requests
    field :resources
    
    class UnknownResource < Stella::Error
      def message; "UnknownResource: #{@obj}"; end
    end
    
    def initialize(&blk)
      @requests, @resources = [], {}
      instance_eval &blk unless blk.nil?
    end
    
    def desc(*args)
      self.description = args.first unless args.empty?
      self.description
    end
    
    def resource(name, value=nil)
      @resources[name] = value unless value.nil?
      @resources[name]
    end
    
    def ratio
      r = (@ratio || 0).to_f
      r = r/100 if r > 1 
      r
    end
    
    def ratio_pretty
      r = (@ratio || 0).to_f
      r > 1.0 ? r.to_i : (r * 100).to_i
    end
    
    # Reads the contents of the file <tt>path</tt> (the current working
    # directory is assumed to be the same directory containing the test plan).
    def read(path)
      path = File.join(base_path, path) if base_path
      Stella.ld "READING FILE: #{path}"
      Stella::Testplan.readlines path
    end
      
    def list(path)
      read(path).collect { |line| line.strip }
    end
    
    def csv(path)
      path = File.join(base_path, path) if base_path
      Stella.ld "READING CSV: #{path}"
      file = Stella::Testplan.readlines path
      CSV.parse file.join
    end
    
    def quickcsv(path)
      path = File.join(base_path, path) if base_path
      Stella.ld "READING CSV(QUICK): #{path}"
      ar = []
      file = Stella::Testplan.readlines path
      file.each do |l|
        l.strip!
        ar << l.split(',')
      end
      ar
    end
    
    def freeze
      @requests.each { |r| r.freeze }
      super
      self
    end
    
    def auth(user, pass=nil, kind=:basic)
      @http_auth ||= Auth.new
      @http_auth.user, @http_auth.pass, @http_auth.kind = user, pass, kind
    end
    
    def add_request(meth, *args, &blk)
      req = Stella::Data::HTTP::Request.new meth.to_s.upcase, args[0], &blk
      req.description = args[1] if args.size > 1 # Description is optional
      Stella.ld req
      @requests << req
      req
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
  
end
end



module Stella
class Testplan

  class Stats
    include Gibbler::Complex
    attr_reader :requests

    def initialize
      @requests = OpenStruct.new
      reset
    end
    
    def total_requests
      @requests.successful + @requests.failed
    end
    
    def reset 
      @requests.successful = 0
      @requests.failed = 0
    end
    
  end
    
end
end
