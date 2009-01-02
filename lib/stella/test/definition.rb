

module Stella
  

  module Test
    
    # Stella::Test::Definition
    # 
    # This class defines the properties of load test. These are "generic" properties
    # in that they don't relate to a specific tool.
    class Definition
      
      # Stella::Test::Definition::Rampup
      # 
      # This class holds the values for a rampup: interval and ceiling.
      class Rampup
        attr_accessor :interval
        attr_accessor :ceiling
        def initialize(interval, ceiling)
          @interval = interval
          @ceiling = ceiling
        end
        def to_s
          to_a.join(',')
        end
        def to_a
          [interval,ceiling]
        end
      end
      
        # Number of virtual users to create or to begin with if rampup is specific.
      attr_accessor :vusers 
        # The total number of requests per test
      attr_accessor :requests 
        # The number of requests per virtual user
      attr_accessor :request_ratio
    
        # Number of times to repeat the test run. Integer.
      attr_reader :repetitions
        # The amount of time to pause between test runs
      attr_accessor :sleep
        # Warmup factor (0.1 - 1) for a single test run before the actual test. 
        # A warmup factor of 0.5 means run a test run at 50% strength. 
      attr_accessor :warmup
        # Contains an interval and maximum threshold to increase virtual users. 
        # Rampup object, [R,M] where R is the interval and M is the maximum. 
      attr_reader :rampup
        # An array of string appropriate for a User-Agent HTTP header
      attr_accessor :agents
        # A short reminder to yourself what you're testing 
      attr_accessor :message
    
      def initialize  
        @repetitions = 3
      end
      
      def repetitions=(v)
        return unless v && v > 0
        @repetitions = v
      end
      
      def rampup=(v)
        return unless v
        
        if (v.is_a? Rampup)
          @rampup = v
        elsif (v.is_a?(Array) && v.size == 2)
          @rampup = Rampup.new(v[0], v[1])
        else
          raise UnknownValue.new(v.to_s)
        end
      end
      
    end
  end
  
end

