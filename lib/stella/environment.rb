module Stella
  class Environment
    
    
  end
end

module Stella
  class Environment
    
    attr_accessor :name
    
      # An array of `Stella::Common::Machine objects to be use during the test.
      #     @stella_environments.machines << "stellaaahhhh.com:80"
    attr_accessor :machines
      # The default proxy, a Stella::Common::Proxy object containing the proxy to be used for the test.
    attr_accessor :proxy
    
    def initialize(name=:development)
      @name = name
      @machines = []
    end

    
    def add_machines(*args)
      return if args.empty?
      args.each do |machine|
        @machines << Stella::Common::Machine.new(machine)
      end
    end
    
    # Creates a Stella::TestPlan::Proxy object and stores it to +@proxy+
    def proxy=(*args)
      uri, user, pass = args.flatten
      @proxy = Stella::Common::Proxy.new(uri, user, pass)
    end
    
    
  end
end

module Stella
  module DSL
    module Environment
      attr_accessor :stella_current_environment

      def environments
        @stella_environments 
      end
    
      def environment(name, &define)
        @stella_environments ||= {}
        @stella_current_environment = @stella_environments[name] = Stella::Environment.new(name)
        define.call if define
      end
      
      def machines(*args)
        return unless @stella_current_environment.is_a? Stella::Environment
        args.each do |machine|
          @stella_current_environment.add_machines machine
        end
      end
      
    end
  end
end