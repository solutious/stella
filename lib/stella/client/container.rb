

class Stella::Client
  
  class Container
    
    attr_accessor :usecase
    attr_accessor :response
    attr_reader :resources
    def initialize(usecase)
      @usecase, @resources = usecase, {}
      @base_path = usecase.base_path
      @random_value = {}
    end
    
    # This is used to handle custom exception in usecases.
    # See examples/exceptions/plan.rb
    #
    def self.const_missing(custom_error)
      ResponseError.new custom_error
    end
    
    def doc
      # NOTE: It's important to parse the document on every 
      # request because this container is available for the
      # entire life of a usecase. 
      case @response.header['Content-Type']
      when ['text/html']
        Nokogiri::HTML(body)
      when ['text/yaml']
        YAML.load(body)
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
    def set(n, v); @resources[n] = v; end
    def wait(t); sleep t; end
    def quit(msg=nil); Quit.new(msg); end
    def repeat(t=1); Repeat.new(t); end
  end
  
end