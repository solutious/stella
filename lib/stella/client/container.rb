

class Stella::Client
  
  class Container
    MUTEX = Mutex.new
    
    attr_accessor :usecase
    attr_accessor :response
    attr_reader :resources
    attr_reader :client_id
    attr_reader :assets
    
    def initialize(client_id, usecase)
      @client_id = client_id
      @usecase, @resources = usecase, {}
      @base_path = usecase.base_path
      @assets = []
      @random_value = {}
    end
    
    @sequential_offset = {}
    @rsequential_offset = {}
    class << self
      def sequential_offset(resid, max)
        MUTEX.synchronize do
          @sequential_offset[resid] ||= -1  
          if @sequential_offset[resid] >= max
            @sequential_offset[resid] = 0 
          else
            @sequential_offset[resid] += 1
          end
          @sequential_offset[resid]
        end
      end
      ## TODO: BROKEN?
      ##def rsequential_offset(resid, max)
      ##  MUTEX.synchronize do
      ##    @rsequential_offset[resid] ||= max+1
      ##    if @rsequential_offset[resid] <= 0
      ##      @rsequential_offset[resid] = max
      ##    else
      ##      @rsequential_offset[resid] -= 1
      ##    end
      ##    @rsequential_offset[resid]
      ##  end
      ##end
    end
    
    # This is used to handle custom exception in usecases.
    # See examples/exceptions/plan.rb
    #
    def self.const_missing(custom_error)
      ResponseError.new custom_error
    end
    
    def fetch(*args)
      @assets.push *args.flatten
    end
    
    def parse_template(t)
      template = ERB.new t
      v = template.result(binding)  
    end
    
    def doc
      # NOTE: It's important to parse the document on every 
      # request because this container is available for the
      # entire life of a usecase. 
      case (@response.header['Content-Type'] || []).first
      when /text\/html/
        Nokogiri::HTML(body)
      when /text\/xml/
        Nokogiri::XML(body)
      when /text\/yaml/
        YAML.load(body)
      when /application\/json/
        JSON.load(body)
      end
    end
    
    # Return a resource from the usecase or from this 
    # container (in that order).
    def resource(n)
      return @usecase.resource(n) if @usecase.resources.has_key? n
      return @resources[n] if @resources.has_key? n
      nil
    end

    def reset_temp_vars
      @random_value = {}
      @sequential_value = {}
      @rsequential_value = {}
    end
    
    def body; @response.body.content; end
    def headers; @response.header; end
      alias_method :header, :headers
    def status; @response.status; end
    def set(*args)
      h = Hash === args[0] ? args[0] : {args[0]=> args[1]}
      @resources.merge! h
    end
    def wait(t); sleep t; end
    def quit(msg=nil); Quit.new(msg); end
    def fail(msg=nil); Fail.new(msg); end
    def repeat(t=1); Repeat.new(t); end
    
    
    
    #
    # QUICK HACK ALERT:
    # Copied from Stella::Data::Helpers, removed Proc.new, just return the value
    #
    
    
    # Can include glob
    #
    # e.g.
    #    random_file('avatar*')
    def random_file(*args)
      input = args.size > 1 ? args : args.first
      
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
    
    def file(*args)
      input = args.size > 1 ? args : args.first
      
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
    
    def random(*args)
      if Symbol === args.first
        input, index = *args
      elsif Array === args.first || args.size == 1
        input = args.first
      else
        input = args
      end
        
      
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
    
    
    # NOTE: This is global across all users
    def sequential(*args)
      if Symbol === args.first
        input, index = *args
      elsif Array === args.first || args.size == 1
        input = args.first
      else
        input = args
      end
      
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
            index = Container.sequential_offset(digest, value.size-1)
            value = value[ index ] 
          end
          Stella.ld "SELECTED(SEQ): #{value} #{index} #{input} #{digest}"
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
  
end