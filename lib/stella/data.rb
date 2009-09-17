
module Stella::Data
    
  module Helpers
    
    def random(*args)
      input = args.size > 1 ? args : args.first
      Proc.new do
        value = case input.class.to_s
        when "Symbol"
          resource(input)
        when "Array"
          input
        when "Range"
          input.to_a
        when "Fixnum"
          Stella::Utils.strand( input )
        when "NilClass"
          Stella::Utils.strand( rand(100) )
        end
        raise Stella::Testplan::Usecase::UnknownResource, input if value.nil?
        Stella.ld "RANDVALUES: #{input} #{value.inspect}"
        value = value[ rand(value.size) ] if value.is_a?(Array)
        Stella.ld "SELECTED: #{value}"
        value
      end
    end
    
    def sequential(*args)
      input = args.size > 1 ? args : args.first
      digest = input.gibbler
      Proc.new do
        value = case input.class.to_s
        when "Symbol"
          ret = resource(input)
          ret
        when "Array"
          input
        when "Range"
          input.to_a
        end
        Stella.ld "SEQVALUES: #{input} #{value.inspect}"
        @sequential_offset ||= {}
        @sequential_offset[digest] ||= 0
        if value.is_a?(Array)
          size = value[ @sequential_offset[digest] ].size
          value = value[ @sequential_offset[digest] ] 
          @sequential_offset[digest] += 1
          @sequential_offset[digest] = 0 if @sequential_offset[digest] > size
        end
        Stella.ld "SELECTED: #{value}"
        value
      end
    end
    
    def rsequential(*args)
      input = args.size > 1 ? args : args.first
      digest = input.gibbler
      Proc.new do
        value = case input.class.to_s
        when "Symbol"
          ret = resource(input)
          ret
        when "Array"
          input
        when "Range"
          input.to_a
        end
        Stella.ld "RSEQVALUES: #{input} #{value.inspect}"
        @rsequential_offset ||= {}
        @rsequential_offset[digest] ||= value.size-1 rescue 1
        if value.is_a?(Array)
          size = value[ @rsequential_offset[digest] ].size
          value = value[ @rsequential_offset[digest] ] 
          @rsequential_offset[digest] -= 1
          @rsequential_offset[digest] = size if @rsequential_offset[digest] < 0
        end
        Stella.ld "SELECTED: #{value}"
        value
      end
    end
    
  end
      
end

Stella::Utils.require_glob(STELLA_LIB_HOME, 'stella', 'data', '*.rb')