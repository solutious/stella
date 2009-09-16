

module Stella
class Testplan
  
  class Usecase
    include Gibbler::Complex
    attr_accessor :desc
    attr_accessor :requests
    attr_writer :ratio
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