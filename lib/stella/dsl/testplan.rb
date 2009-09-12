

module Stella
  module DSL
    module Testplan 
      
      def self.parse_file(path)
        conf = File.read path
        parse conf, path
      end
      
      def self.parse(conf, path=self)
        plan = Stella::Testplan.new
        # eval so the DSL code can be executed in this namespace.
        plan.instance_eval conf, binding, path
      end
        
      def self.usecase(percentage=100, &blk)
        p percentage
      end
      
    end
  end
end
