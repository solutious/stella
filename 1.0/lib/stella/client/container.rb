

class Stella::Client
  
  class Container
    MUTEX = Mutex.new
    
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
      
      def rsequential_offset(resid, max)
        MUTEX.synchronize do
          @rsequential_offset[resid] ||= max+1
          if @rsequential_offset[resid] <= 0
            @rsequential_offset[resid] = max
          else
            @rsequential_offset[resid] -= 1
          end
          @rsequential_offset[resid]
        end
      end
    end
    
    # This is used to handle custom exception in usecases.
    # See examples/exceptions/plan.rb
    #
    def self.const_missing(custom_error)
      ResponseError.new custom_error
    end
    
    
    attr_accessor :usecase
    attr_accessor :params
    attr_accessor :headers
    attr_accessor :response
    attr_accessor :unique_id
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
    
    def params(key=nil)
      key.nil? ? @params : @params[key]
    end
    alias_method :param, :params
    
    def headers(key=nil)
      key.nil? ? @headers : @headers[key]
    end
    alias_method :header, :headers
    
    # This is intended to be called in between requests.
    def reset_temp_vars
      @random_value = {}
      @sequential_value = {}
      @rsequential_value = {}
      @doc, @forms, @assets = nil, nil, []
    end
    
    
    
    def fetch(*args)
      @assets.push *args.flatten
    end
    
    def parse_template(t)
      # ERB BUG?: Under heavy threading, some calls
      # produce the error:
      # wrong number of arguments(1 for 0)
      v = t.result(binding)  
    rescue => ex
      Stella.ld ex.message, ex.backtrace
      t.to_s
    end
    
    def doc
      return @doc unless @doc.nil?
      return nil if body.nil? || body.empty?
      str = RUBY_VERSION >= "1.9.0" ? body.force_encoding("UTF-8") : body
      # NOTE: It's important to parse the document on every 
      # request because this container is available for the
      # entire life of a usecase. 
      @doc = case (@response.header['Content-Type'] || []).first
      when /text\/html/
        Nokogiri::HTML(str)
      when /text\/xml/
        Nokogiri::XML(str)
      when /text\/yaml/
        YAML.load(str)
      when /application\/json/
        JSON.load(str)
      end
    end
    
    class Form < Hash
      def fields(key)
        self['input'] ||= {}
        self['input'][key]
      end
      alias_method :field, :fields
      class << self
        # Create an instance from a Nokogiri::HTML::Document
        def from_doc(doc)
          f = new
          doc.each { |n,v| f[n] = v }
          f['input'] = {}
          (doc.css('input') || []).each do |input|
            f['input'][input['name']] = input['value']
          end
          f
        end
      end
      
    end
    
    def forms(fid=nil)
      if @forms.nil? && Nokogiri::HTML::Document === doc
        @forms, index = {}, 0
        (doc.css('form') || []).each do |html|
          name = html['id'] || html['name'] || html['class']
          Stella.ld [:form, name, index].inspect
          # Store the form by the name and index in the document
          @forms[name] = @forms[index] = Form.from_doc(html)
          index += 1
        end
      end
      (fid.nil? ? @forms : @forms[fid])
    end
    alias_method :form, :forms
    
    # Return a resource from this container or from  
    # the usecase (in that order). Otherwise, nil. 
    def resource(n)
      n &&= n.to_sym
      v = @resources.has_key?(n) ? @resources[n] : @usecase.resource(n)
      v = Stella::Testplan.global(n) if Stella::Testplan.global?(n)
      v
    end
    
    def resource?(n)
      !resource(n).nil?
    end
    
    def body; @response.body.content; end
    def headers; @response.header; end
      alias_method :header, :headers
    def status; @response.status; end
    def set(name, *args)
      if Hash === name
        Stella.ld "ARGS IGNORED: #{args.inspect} (#{caller[0]})" if !args.empty?
        @resources.merge! name
      elsif !name.nil? && !args.empty?
        @resources.merge!({name => args[0]})
      end
    end
    def wait(t); sleep t; end
    def quit(msg=nil); Quit.new(msg); end
    def fail(msg=nil); Fail.new(msg); end
    def error(msg=nil); Error.new(msg); end
    def repeat(t=1); Repeat.new(t); end
    def follow(uri=nil,&blk); Follow.new(uri,&blk); end
    
    
    
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
    
    def path(*args)
      input = File.join *args
      File.exists?(input) ? input : File.join(@base_path, input)
    end
    
    def read_file(*args)
      f = file *args
      f.read
    end
    
    def random(*args)
      input, idxcol = *std_arg_processor(*args)
      input.digest
      if @random_value[input.digest_cache]
        value = @random_value[input.digest_cache]
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
        @random_value[input.digest_cache] = value
      end
      
      # The resource may be an Array of Arrays (e.g. a CSV file)
      if value.is_a?(Array) && !idxcol.nil?
        value = value[ idxcol ] 
        Stella.ld "SELECTED INDEX: #{idxcol} #{value.inspect} "
      end
      
      value
      
    end
    
    
    
    # NOTE: This is global across all users
    def sequential(*args)
      input, idxcol = *std_arg_processor(*args)
      input.digest # prime the cache
      if @sequential_value[input.digest_cache]
        value = @sequential_value[input.digest_cache]
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
        digest = value.digest
        if value.is_a?(Array)
          vsize = value.size
          idxrow = Stella::Client::Container.sequential_offset(digest, value.size-1)
          value = value[ idxrow ] 
          Stella.ld "SELECTED(SEQ): #{value} #{idxrow} (of #{vsize-1}) #{input} #{digest}"
        end
        # I think this needs to be updated for global_sequential:
        @sequential_value[input.digest_cache] = value
      end
      # The resource may be an Array of Arrays (e.g. a CSV file)
      if value.is_a?(Array) && !idxcol.nil?
        value = value[ idxcol ] 
        Stella.ld "SELECTED INDEX: #{idxcol} #{value.inspect} "
      end
      
      value
      
    end
    

    # NOTE: This is global across all users
    def rsequential(*args)
      input, idxcol = *std_arg_processor(*args)
      input.digest
      if @rsequential_value[input.digest_cache]
        value = @rsequential_value[input.digest_cache]
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
        digest = value.digest
        if value.is_a?(Array)
          idxrow = Stella::Client::Container.rsequential_offset(digest, value.size-1)
          value = value[ idxrow ] 
          Stella.ld "SELECTED(RSEQ): #{value} #{idxrow} #{input} #{digest}"
        end
        
        # I think this needs to be updated for global_sequential:
        @rsequential_value[input.digest_cache] = value
      end
      # The resource may be an Array of Arrays (e.g. a CSV file)
      if value.is_a?(Array) && !idxcol.nil?
        value = value[ idxcol ] 
        Stella.ld "SELECTED INDEX: #{idxcol} #{value.inspect} "
      end
      value
      
    end
    
    
    private 
    
    def std_arg_processor(*args)
      input, idxcol = nil, nil
      if Symbol === args.first
        input, idxcol = *args
      elsif Array === args.first || args.size == 1
        input = args.first
      else
        input = args
      end
      [input, idxcol]
    end
    
    
  end
  
end