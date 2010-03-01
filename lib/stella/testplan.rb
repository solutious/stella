

module Stella
  class Testplan < Storable
    include Gibbler::Complex
    extend Attic
    
    # Stuff in the attic won't be included in the digest
    attic :base_path
    attic :plan_path
    attic :description
    
    field :id, &gibbler_id_processor
    field :description => String
    field :usecases => Array
    
    def initialize(desc=nil)
      self.description = "Test plan"
      @usecases = []
    end
    
    def self.load_file(path)
      raise Stella::Error, "Bad path: #{path}" unless File.exists?(path)
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
        u.ratio = ((1.0-calculate_used_ratio) / needy.size).to_f
      end
      if calculate_used_ratio > 1.0 
        msg = "Usecase ratio cannot be higher than 1.0"
        msg << " (#{calculate_used_ratio})"
        raise Stella::WackyRatio, msg
      end
    end
    
    def calculate_used_ratio
      @usecases.inject(0) { |total,u| total += u.ratio }
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
      add_usecase uc
    end
    def xusecase(*args, &blk) Stella.ld "Skipping usecase" end

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
    
  end
end


module Stella
  class Testplan
    class Usecase < Storable
      include Gibbler::Complex
      extend Attic
      
      attic :base_path # we don't want gibbler to see this
      attic :plan_path
      attic :description
      
      field :id, &gibbler_id_processor
      
      field :description

      field :ratio
      field :auth
      field :timeout
      field :requests
      field :resources
      
      def initialize(&blk)
        @requests, @resources = [], {}
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
      
      
      def auth(user, pass=nil, domain=nil)
        @http_auth ||= Auth.new
        @http_auth.user, @http_auth.pass, @http_auth.domain = user, pass, domain
      end

      
      private
      def skip(meth, desc=nil)
        Stella.ld "Skipping #{meth} #{desc}"
      end
      
    end
    
    
  end
  
end

Stella::Events.load
