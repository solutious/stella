

module Stella::Data::HTTP
  class Request < Storable
    include Gibbler::Complex
    include Stella::Data::Helpers
    
    field :id => String, &gibbler_id_processor
    
      # A hash containing blocks to be executed depending on the HTTP response status.
      # The hash keys are numeric HTTP Status Codes. 
      #
      #     200 => { ... }
      #     304 => { ... }
      #     500 => { ... }
      #
    field :response_handler => Hash, &hash_proc_processor
    
    # Store the description in the attic so
    # it's not used in the gibbler digest.
    attic :description
    field :description
    
    field :header => Hash
    field :uri
    field :wait => Range
    field :params => Hash
    field :body 
    field :http_method
    field :http_version
    field :content_type
    field :http_auth
    field :timeout => Float
    
    field :autofollow  # boolean. Was this an auto generated follow request. 

    
    def has_body?
      !@body.nil?
    end
    
    def id
      Gibbler::Digest.new @id || self.digest
    end
    
    def initialize (method=nil, uri_str=nil, version="1.1", &definition)
      @uri = uri_str.to_s
      @http_method, @http_version = method, version
      @header, @params, @response_handler = {}, {}, {}
      @resources = {}
      @autofollow = false
      @wait = 0..0
      self.description = "Request"
      instance_eval &definition unless definition.nil?
    end
    
    def autofollow!
      @autofollow = true
    end
    
    def self.from_hash(hash={})
      me = super(hash)
      me.response_handler.keys.each do |status|
        proc_str = me.response_handler[status]
        me.response_handler[status] = eval "Proc.new #{proc_str}"
        me.response_handler[status].source = proc_str
      end
      me
    end
    
    def auth(user=nil, pass=nil, domain=nil)
      @http_auth ||= Stella::Testplan::Usecase::Auth.new
      @http_auth.user, @http_auth.pass, @http_auth.domain = user, pass, domain
    end
    
    def timeout(*args)
      @timeout = args.first unless args.empty?
      @timeout
    end
    
    def desc(*args)
      self.description = args.first unless args.empty?
      self.description
    end
    
    def content_type(*args)
      @content_type = args.first unless args.empty?
      @content_type
    end
    
    def wait(*args)
      args = [args].flatten.compact
      @wait = args.first unless args.empty?
      @wait
    end
    alias_method :sleep, :wait
    
    def headers(*args)
      args = [args].flatten.compact
      unless args.empty?
        h = Hash === args[0] ? args[0] : {args[0]=> args[1]}
        @header.merge! h unless h.empty?
      end
      @header
    end
    alias_method :header, :headers
    
    # Set a resource key value pair in the get, post block.
    # These will be process later in Stella::Client
    def set(*args)
      args = [args].flatten.compact
      unless args.empty?
        h = Hash === args[0] ? args[0] : {args[0]=> args[1]}
        @resources.merge! h unless h.empty?
      end
      @resources
    end
    alias_method :resources, :set
    
    def params(*args)
      args = [args].flatten.compact
      unless args.empty?
        h = Hash === args[0] ? args[0] : {args[0]=> args[1]}
        @params.merge! h unless h.empty?
      end
      @params
    end
    alias_method :param, :params
    
    def response(*args, &definition)
      if definition.nil?
        @response_handler
      else
        args << /.+/ if args.empty?
        args.each do |status|
          @response_handler[status] = definition
        end
      end
    end
    
    # +content+ can be literal content or a file path
    def body(*args)
      return @body if args.empty?
      @body = args.first
    end
    
    def inspect
      str = "%s %s" % [http_method, uri.to_s, http_version]
      #str << $/ + headers.join($/) unless headers.empty?
      #str << $/ + $/ + body.to_s if body
      str
    end
    
    def to_s
      str = "%s %s" % [http_method, uri.to_s, http_version]
      str
    end
    
    def cookies
      return [] if !header.is_a?(Hash) || header[:Cookie].empty?
      header[:Cookie] 
    end
    
    def freeze
      return if frozen?
      @params = convert_values_to_templates @params
      @header = convert_values_to_templates @header
      super
      self
    end
    
    private 
     def convert_values_to_templates(hash)
       updated = {}
       hash.each_pair { |k,v| 
         next if Stella::Template === v
         if Proc === v
           msg = "As of Stella 0.8, Procs are no longer supported as values#{$/}"
           msg << "for parameters and headers (\"#{k}\" in \"#{description}\").#{$/}"
           msg << "Use string templates instead. See the examples/ directory."
           raise Stella::Error, msg
         end
         updated[k] = Stella::Template.new( v || '')
       }
       updated
     end
  end
  
end