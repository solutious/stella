
module Stella::Data
  extend self
    
  module Helpers
    
    def resource(name)
      Proc.new do
        resource name 
      end
    end
    
    # Can include glob
    #
    # e.g.
    #    random_file('avatar*')
    def random_file(*args)
      input = args.size > 1 ? args : args.first
      Proc.new do
        value = case input.class.to_s
        when "String"
          Stella.ld "FILE: #{input}"
          path = File.exists?(input) ? input : File.join(@base_path, input)
          files = Dir.glob(path)
          path = files[ rand(files.size) ]
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
    
    def read_file(*args)
      input = args.size > 1 ? args : args.first
      Proc.new do
        case input.class.to_s
        when "String"
          file(input).read  # This is the file method defined in Container.
        when "Proc"
          input.call
        else
          input
        end
      end
    end
    
    def path(*args)
      input = File.join *args
      Proc.new do
        File.exists?(input) ? input : File.join(@base_path, input)
      end
    end
    
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
      if Symbol === args.first
        input, index = *args
      elsif Array === args.first || args.size == 1
        input = args.first
      else
        input = args
      end
        
      Proc.new do
        if @random_value[input.object_id]
          value = @random_value[input.object_id]
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
          @random_value[input.object_id] = value
        end
        
        # The resource may be an Array of Arrays (e.g. a CSV file)
        if value.is_a?(Array) && !index.nil?
          value = value[ index ] 
          Stella.ld "SELECTED INDEX: #{index} #{value.inspect} "
        end
        
        value
      end
    end
    
    
    # NOTE: This is global across all users
    def sequential(*args)
      if Symbol === args.first
        input, index = *args
      elsif Array === args.first || args.size == 1
        input = args.first
      else
        input = args
      end
      Proc.new do
        if @sequential_value[input.object_id]
          value = @sequential_value[input.object_id]
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
          digest = value.object_id
          if value.is_a?(Array)
            idx = Stella::Client::Container.sequential_offset(digest, value.size-1)
            value = value[ idx ] 
            Stella.ld "SELECTED(SEQ): #{value} #{idx} #{input} #{digest}"
          end
          
          # I think this needs to be updated for global_sequential:
          @sequential_value[input.object_id] = value
        end
        # The resource may be an Array of Arrays (e.g. a CSV file)
        if value.is_a?(Array) && !index.nil?
          value = value[ index ] 
          Stella.ld "SELECTED INDEX: #{index} #{value.inspect} "
        end
        value
      end
    end
    
    # NOTE: This is global across all users
    def rsequential(*args)
      if Symbol === args.first
        input, index = *args
      elsif Array === args.first || args.size == 1
        input = args.first
      else
        input = args
      end
      Proc.new do
        if @rsequential_value[input.object_id]
          value = @rsequential_value[input.object_id]
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
          digest = value.object_id
          if value.is_a?(Array)
            idx = Stella::Client::Container.rsequential_offset(digest, value.size-1)
            value = value[ idx ] 
            Stella.ld "SELECTED(RSEQ): #{value} #{idx} #{input} #{digest}"
          end
          
          # I think this needs to be updated for global_sequential:
          @rsequential_value[input.object_id] = value
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