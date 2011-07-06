require 'ostruct'

module Familia
  require 'familia/redisobject'
  
  # Auto-extended into a class that includes Familia
  module ClassMethods
    
    Familia::RedisObject.registration.each_pair do |kind, klass|
      # e.g. 
      #
      #      list(name, klass, opts)
      #      list?(name)
      #      lists
      #
      define_method :"#{kind}" do |*args, &blk|
        name, opts = *args
        install_redis_object name, klass, opts
        redis_objects[name.to_s.to_sym]
      end
      define_method :"#{kind}?" do |name|
        obj = redis_objects[name.to_s.to_sym]
        !obj.nil? && klass == obj.klass
      end
      define_method :"#{kind}s" do 
        names = redis_objects_order.select { |name| send(:"#{kind}?", name) }
        names.collect! { |name| redis_objects[name] }
        names
      end
      # e.g. 
      #
      #      class_list(name, klass, opts)
      #      class_list?(name)
      #      class_lists
      #
      define_method :"class_#{kind}" do |*args, &blk|
        name, opts = *args
        install_class_redis_object name, klass, opts
      end
      define_method :"class_#{kind}?" do |name|
        obj = class_redis_objects[name.to_s.to_sym]
        !obj.nil? && klass == obj.klass
      end
      define_method :"class_#{kind}s" do 
        names = class_redis_objects_order.select { |name| ret = send(:"class_#{kind}?", name) }
        # TODO: This returns instances of the RedisObject class which
        # also contain the options. This is different from the instance
        # RedisObjects defined above which returns the OpenStruct of name, klass, and opts. 
        #names.collect! { |name| self.send name }
        # OR NOT:
        names.collect! { |name| class_redis_objects[name] }
        names
      end
    end
    def inherited(obj)
      obj.db = self.db
      obj.uri = self.uri
      obj.ttl = self.ttl
      obj.parent = self
      obj.class_zset :instances, :class => obj, :reference => true
      Familia.classes << obj
      super(obj)
    end
    def extended(obj)
      obj.db = self.db
      obj.ttl = self.ttl
      obj.uri = self.uri
      obj.parent = self
      obj.class_zset :instances, :class => obj, :reference => true
      Familia.classes << obj
    end
    
    # Creates an instance method called +name+ that
    # returns an instance of the RedisObject +klass+ 
    def install_redis_object name, klass, opts
      raise ArgumentError, "Name is blank" if name.to_s.empty?
      name = name.to_s.to_sym
      opts ||= {}
      redis_objects_order << name
      redis_objects[name] = OpenStruct.new
      redis_objects[name].name = name
      redis_objects[name].klass = klass
      redis_objects[name].opts = opts
      self.send :attr_reader, name
      define_method "#{name}=" do |v|
        self.send(name).replace v
      end
      define_method "#{name}?" do
        !self.send(name).empty?
      end
      redis_objects[name]
    end
    
    def qstamp quantum=nil, pattern=nil, now=Familia.now
      quantum ||= ttl || 10.minutes
      pattern ||= '%H%M'
      rounded = now - (now % quantum)
      Time.at(rounded).utc.strftime(pattern)
    end
    
    # Creates a class method called +name+ that
    # returns an instance of the RedisObject +klass+ 
    def install_class_redis_object name, klass, opts
      raise ArgumentError, "Name is blank" if name.to_s.empty?
      name = name.to_s.to_sym
      opts = opts.nil? ? {} : opts.clone
      opts[:parent] = self unless opts.has_key?(:parent)
      # TODO: investigate using metaclass.redis_objects
      class_redis_objects_order << name
      class_redis_objects[name] = OpenStruct.new
      class_redis_objects[name].name = name
      class_redis_objects[name].klass = klass
      class_redis_objects[name].opts = opts 
      # An accessor method created in the metclass will
      # access the instance variables for this class. 
      metaclass.send :attr_reader, name
      metaclass.send :define_method, "#{name}=" do |v|
        send(name).replace v
      end
      metaclass.send :define_method, "#{name}?" do
        !send(name).empty?
      end
      redis_object = klass.new name, opts
      redis_object.freeze
      self.instance_variable_set("@#{name}", redis_object)
      class_redis_objects[name]
    end
    
    def from_redisdump dump
      dump # todo
    end
    attr_accessor :parent
    def ttl v=nil
      @ttl = v unless v.nil?
      @ttl || (parent ? parent.ttl : nil)
    end
    def ttl=(v) @ttl = v end
    def db v=nil
      @db = v unless v.nil?
      @db || (parent ? parent.db : nil)
    end
    def db=(db) @db = db end
    def host(host=nil) @host = host if host; @host end
    def host=(host) @host = host end
    def port(port=nil) @port = port if port; @port end
    def port=(port) @port = port end
    def uri=(uri)
      uri = URI.parse uri if String === uri
      @uri = uri 
    end
    def uri(uri=nil) 
      self.uri = uri if !uri.to_s.empty?
      @uri ||= (parent ? parent.uri : Familia.uri)
      @uri.db = @db if @db && @uri.db.to_s != @db.to_s
      @uri
    end
    def redis
      Familia.redis uri
    end
    def flushdb
      Familia.info "flushing #{uri}"
      redis.flushdb
    end
    def keys(suffix=nil)
      self.redis.keys(rediskey('*',suffix)) || []
    end
    def all(suffix=:object)
      # objects that could not be parsed will be nil
      keys(suffix).collect { |k| from_key(k) }.compact 
    end
    def any?(filter='*')
      size(filter) > 0
    end
    def size(filter='*')
      self.redis.keys(rediskey(filter)).compact.size
    end
    def suffix(a=nil, &blk) 
      @suffix = a || blk if a || !blk.nil?
      val = @suffix || Familia.default_suffix
      val
    end
    def prefix=(a) @prefix = a end
    def prefix(a=nil) @prefix = a if a; @prefix || self.name.downcase.gsub('::', Familia.delim).to_sym end
    # TODO: grab db, ttl, uri from parent
    #def parent=(a) @parent = a end
    #def parent(a=nil) @parent = a if a; @parent end
    def index(i=nil, &blk) 
      @index = i || blk if i || !blk.nil?
      @index ||= Familia.index
      @index
    end
    def suffixes
      redis_objects.keys.uniq
    end
    def class_redis_objects_order
      @class_redis_objects_order ||= []
      @class_redis_objects_order
    end
    def class_redis_objects
      @class_redis_objects ||= {}
      @class_redis_objects
    end
    def class_redis_objects? name
      class_redis_objects.has_key? name.to_s.to_sym
    end
    def redis_object? name
      redis_objects.has_key? name.to_s.to_sym
    end
    def redis_objects_order
      @redis_objects_order ||= []
      @redis_objects_order
    end
    def redis_objects
      @redis_objects ||= {}
      @redis_objects
    end
    def create *args
      me = from_array *args
      raise "#{self} exists: #{me.rediskey}" if me.exists?
      me.save
      me
    end
    def multiget(*ids)
      ids = rawmultiget(*ids)
      ids.compact.collect { |json| self.from_json(json) }.compact
    end
    def rawmultiget(*ids)
      ids.collect! { |objid| rediskey(objid) }
      return [] if ids.compact.empty?
      Familia.trace :MULTIGET, self.redis, "#{ids.size}: #{ids}", caller if Familia.debug?
      ids = self.redis.mget *ids
    end
    
    # Returns an instance based on +idx+ otherwise it
    # creates and saves a new instance base on +idx+. 
    # See from_index
    def load_or_create idx
      return from_redis(idx) if exists?(idx)
      obj = from_index idx
      obj.save
      obj
    end
    # Note +idx+ needs to be an appropriate index for 
    # the given class. If the index is multi-value it
    # must be passed as an Array in the proper order.
    # Does not call save.
    def from_index idx
      obj = new 
      obj.index = idx
      obj
    end
    def from_key objkey
      raise ArgumentError, "Empty key" if objkey.to_s.empty?    
      Familia.trace :LOAD, Familia.redis(self.uri), objkey, caller if Familia.debug?
      obj = Familia::String.new objkey, :class => self
      obj.value
    end
    def from_redis idx, suffix=:object
      return nil if idx.to_s.empty?
      objkey = rediskey idx, suffix
      #Familia.trace :FROMREDIS, Familia.redis(self.uri), objkey, caller.first if Familia.debug?
      me = from_key objkey
      me
    end
    def exists? idx, suffix=:object
      return false if idx.to_s.empty?
      objkey = rediskey idx, suffix
      ret = Familia.redis(self.uri).exists objkey
      Familia.trace :EXISTS, Familia.redis(self.uri), "#{rediskey(idx, suffix)} #{ret}", caller if Familia.debug?
      ret
    end
    def destroy! idx, suffix=:object
      ret = Familia.redis(self.uri).del rediskey(idx, suffix)
      Familia.trace :DELETED, Familia.redis(self.uri), "#{rediskey(idx, suffix)}: #{ret}", caller if Familia.debug?
      ret
    end
    def find suffix='*'
      list = Familia.redis(self.uri).keys(rediskey('*', suffix)) || []
    end
    # idx can be a value or an Array of values used to create the index.
    # We don't enforce a default suffix; that's left up to the instance.
    # A nil +suffix+ will not be included in the key.
    def rediskey idx, suffix=self.suffix
      raise RuntimeError, "No index for #{self}" if idx.to_s.empty?
      idx = Familia.join *idx if Array === idx
      idx &&= idx.to_s
      Familia.rediskey(prefix, idx, suffix)
    end
    def expand(short_idx, suffix=self.suffix)
      expand_key = Familia.rediskey(self.prefix, "#{short_idx}*", suffix)
      Familia.trace :EXPAND, Familia.redis(self.uri), expand_key, caller.first if Familia.debug?
      list = Familia.redis(self.uri).keys expand_key
      case list.size
      when 0
        nil
      when 1 
        matches = list.first.match(/\A#{Familia.rediskey(prefix)}\:(.+?)\:#{suffix}/) || []
        matches[1]
      else
        raise Familia::NonUniqueKey, "Short key returned more than 1 match" 
      end
    end
  end

  
  module InstanceMethods
    
    # A default initialize method. This will be replaced
    # if a class defines its own initialize method after
    # including Familia. In that case, the replacement
    # must call initialize_redis_objects.
    def initialize *args
      initialize_redis_objects
      init *args if respond_to? :init
    end
    
    # This needs to be called in the initialize method of
    # any class that includes Familia. 
    def initialize_redis_objects
      # Generate instances of each RedisObject. These need to be
      # unique for each instance of this class so they can refer
      # to the index of this specific instance.
      #
      # i.e. 
      #     familia_object.rediskey              == v1:bone:INDEXVALUE:object
      #     familia_object.redis_object.rediskey == v1:bone:INDEXVALUE:name
      #
      # See RedisObject.install_redis_object
      self.class.redis_objects.each_pair do |name, redis_object_definition|
        klass, opts = redis_object_definition.klass, redis_object_definition.opts
        opts = opts.nil? ? {} : opts.clone
        opts[:parent] = self unless opts.has_key?(:parent)
        redis_object = klass.new name, opts
        redis_object.freeze
        self.instance_variable_set "@#{name}", redis_object
      end
    end
    
    def qstamp quantum=nil, pattern=nil, now=Familia.now
      self.class.qstamp ttl, pattern, now
    end
    
    def from_redis 
      self.class.from_redis self.index
    end
    
    def redis
      self.class.redis
    end
    
    def redisinfo
      info = {
        :uri  => self.class.uri,
        :db   => self.class.db,
        :key  => rediskey,
        :type => redistype,
        :ttl  => realttl
      }
    end
    def exists?
      Familia.redis(self.class.uri).exists rediskey
    end      
    
    #def rediskeys
    #  self.class.redis_objects.each do |redis_object_definition|
    #    
    #  end
    #end
    
    def allkeys
      # TODO: Use redis_objects instead
      keynames = []
      self.class.suffixes.each do |sfx| 
        keynames << rediskey(sfx)
      end
      keynames
    end
    # +suffix+ is the value to be used at the end of the redis key
    # + ignored+ is literally ignored. It's around to maintain
    # consistency with the class version of this method. 
    # (RedisObject#rediskey may call against a class or instance).
    def rediskey(suffix=nil, ignored=nil)
      Familia.info "[#{self.class}] something was ignored" unless ignored.nil?
      raise Familia::NoIndex, self.class if index.to_s.empty?
      if suffix.nil?
        suffix = self.class.suffix.kind_of?(Proc) ? 
                     self.class.suffix.call(self) : 
                     self.class.suffix
      end
      self.class.rediskey self.index, suffix
    end
    def object_proxy
      @object_proxy ||= Familia::String.new self.rediskey, :ttl => ttl, :class => self.class
      @object_proxy
    end
    def save meth=:set
      #Familia.trace :SAVE, Familia.redis(self.class.uri), redisuri, caller.first if Familia.debug?
      preprocess if respond_to?(:preprocess)
      self.update_time if self.respond_to?(:update_time)
      ret = object_proxy.send(meth, self)       # object is a name reserved by Familia
      unless ret.nil?
        now = Time.now.utc.to_i
        self.class.instances.add now, self     # use this set instead of Klass.keys
        object_proxy.update_expiration        # does nothing unless if not specified
      end
      ret == "OK" || ret == true || ret == 1
    end
    def savenx 
      save :setnx
    end
    def update! hsh=nil
      updated = false
      hsh ||= {}
      if hsh.empty?
        raise Familia::Problem, "No #{self.class}#{to_hash} method" unless respond_to?(:to_hash)
        ret = from_redis
        hsh = ret.to_hash if ret
      end
      hsh.keys.each { |field| 
        v = hsh[field.to_s] || hsh[field.to_s.to_sym]
        next if v.nil?
        self.send(:"#{field}=", v) 
        updated = true
      }
      updated
    end
    def destroy!
      ret = object_proxy.delete
      if Familia.debug?
        Familia.trace :DELETED, Familia.redis(self.class.uri), "#{rediskey}: #{ret}", caller.first if Familia.debug?
      end
      self.class.instances.rem self if ret > 0
      ret
    end
    def index
      case self.class.index
      when Proc
        self.class.index.call(self)
      when Array
        parts = self.class.index.collect { |meth| 
          unless self.respond_to? meth
            raise NoIndex, "No such method: `#{meth}' for #{self.class}"
          end
          ret = self.send(meth)
          ret = ret.index if ret.kind_of?(Familia)
          ret
        }
        parts.join Familia.delim
      when Symbol, String
        if self.class.redis_object?(self.class.index.to_sym)
          raise Familia::NoIndex, "Cannot use a RedisObject as an index"
        else
          unless self.respond_to? self.class.index
            raise NoIndex, "No such method: `#{self.class.index}' for #{self.class}"
          end
          ret = self.send(self.class.index)
          ret = ret.index if ret.kind_of?(Familia)
          ret
        end
      else
        raise Familia::NoIndex, self
      end
    end
    def index=(v)
      case self.class.index
      when Proc
        raise ArgumentError, "Cannot set a Proc index"
      when Array
        unless Array === v && v.size == self.class.index.size
          raise ArgumentError, "Index mismatch (#{v.size} for #{self.class.index.size})"
        end
        parts = self.class.index.each_with_index { |meth,idx| 
          unless self.respond_to? "#{meth}="
            raise NoIndex, "No such method: `#{meth}=' for #{self.class}"
          end
          self.send("#{meth}=", v[idx]) 
        }
      when Symbol, String
        if self.class.redis_object?(self.class.index.to_sym)
          raise Familia::NoIndex, "Cannot use a RedisObject as an index"
        else
          unless self.respond_to? "#{self.class.index}="
            raise NoIndex, "No such method: `#{self.class.index}=' for #{self.class}"
          end
          self.send("#{self.class.index}=", v)
        end
      else
        raise Familia::NoIndex, self
      end
      
    end
    def expire(ttl=nil)
      ttl ||= self.class.ttl
      Familia.redis(self.class.uri).expire rediskey, ttl.to_i
    end
    def realttl
      Familia.redis(self.class.uri).ttl rediskey
    end
    def ttl=(v)
      @ttl = v.to_i
    end
    def ttl
      @ttl || self.class.ttl
    end
    def raw(suffix=nil)
      suffix ||= :object
      Familia.redis(self.class.uri).get rediskey(suffix)
    end
    def redisuri(suffix=nil)
      u = URI.parse self.class.uri.to_s
      u.db ||= self.class.db.to_s
      u.key = rediskey(suffix)
      u
    end
    def redistype(suffix=nil)
      Familia.redis(self.class.uri).type rediskey(suffix)
    end
    # Finds the shortest available unique key (lower limit of 6)
    def shortid
      len = 6
      loop do
        begin
          self.class.expand(@id.shorten(len))
          break
        rescue Familia::NonUniqueKey
          len += 1
        end
      end
      @id.shorten(len) 
    end
  end
  
end