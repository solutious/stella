
module Stella::Data
    
  module Helpers
    
    def file(*args)
      input = args.size > 1 ? args : args.first
      Proc.new do
        value = case input.class.to_s
        when "String"
          Stella.ld "FILE: #{input}"
          path = File.exists?(input) ? input : File.join(@base_path, input)
          Stella.ld "Creating file object: #{path}"
          File.new(path)
        when "Proc"
          input.call
        else
          input
        end
        raise Stella::Testplan::Usecase::UnknownResource, input if value.nil?
        Stella.ld "FILE: #{value}"
        value
      end
    end
    
    def random(*args)
      input, index = *args
      Proc.new do
        if @random_value[input]
          value = @random_value[input]
        else
          value = case input.class.to_s
          when "Symbol"
            resource(input)
          when "Array"
            input
          when "Range"
            input.to_a
          when "Proc"
            input.call
          when "Fixnum"
            Stella::Utils.strand( input )
          when "NilClass"
            Stella::Utils.strand( rand(100) )
          end
          raise Stella::Testplan::Usecase::UnknownResource, input if value.nil?
          Stella.ld "RANDVALUES: #{input} #{value.class} #{value.inspect}"
          value = value[ rand(value.size) ] if value.is_a?(Array)
          Stella.ld "SELECTED: #{value.class} #{value} "
          @random_value[input] = value
        end
        
        # The resource may be an Array of Arrays (e.g. a CSV file)
        if value.is_a?(Array) && !index.nil?
          value = value[ index ] 
          Stella.ld "SELECTED INDEX: #{index} #{value.inspect} "
        end
        
        value
      end
    end
    
    def sequential(*args)
      input, index = *args
      Proc.new do
        if @sequential_value[input]
          value = @sequential_value[input]
        else
          value = case input.class.to_s
          when "Symbol"
            ret = resource(input)
            ret
          when "Array"
            input
          when "Range"
            input.to_a
          when "Proc"
            input.call
          end
          digest = value.gibbler
          @sequential_offset ||= {}
          @sequential_offset[digest] ||= 0
          Stella.ld "SEQVALUES: #{input} #{value.inspect} #{@sequential_offset[digest]}"
          if value.is_a?(Array)
            size = value.size
            @sequential_offset[digest] = 0 if @sequential_offset[digest] >= size
            value = value[ @sequential_offset[digest] ] 
            @sequential_offset[digest] += 1
          end
          Stella.ld "SELECTED: #{value}"
          @sequential_value[input] = value
        end
        # The resource may be an Array of Arrays (e.g. a CSV file)
        if value.is_a?(Array) && !index.nil?
          value = value[ index ] 
          Stella.ld "SELECTED INDEX: #{index} #{value.inspect} "
        end
        value
      end
    end
    
    def rsequential(*args)
      input, index = *args
      Proc.new do
        if @rsequential_value[input.digest]
          value = @rsequential_value[input.digest]
        else
          value = case input.class.to_s
          when "Symbol"
            ret = resource(input)
            ret
          when "Array"
            input
          when "Range"
            input.to_a
          when "Proc"
            input.call
          end
          digest = value.gibbler
          @rsequential_offset ||= {}
          @rsequential_offset[digest] ||= value.size-1 rescue 1
          Stella.ld "RSEQVALUES: #{input} #{value.inspect} #{@rsequential_offset[digest]}"
          if value.is_a?(Array)
            size = value.size
            @rsequential_offset[digest] = size-1 if @rsequential_offset[digest] < 0
            value = value[ @rsequential_offset[digest] ] 
            @rsequential_offset[digest] -= 1
          end
          Stella.ld "SELECTED: #{value}"
          @rsequential_value[input.digest] = value
        end
        
        # The resource may be an Array of Arrays (e.g. a CSV file)
        if value.is_a?(Array) && !index.nil?
          value = value[ index ] 
          Stella.ld "SELECTED INDEX: #{index} #{value.inspect} "
        end
        
        value
      end
    end
    
  end
      
end

Stella::Utils.require_glob(STELLA_LIB_HOME, 'stella', 'data', '*.rb')