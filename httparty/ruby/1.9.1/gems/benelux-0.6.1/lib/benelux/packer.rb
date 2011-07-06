

module Benelux
  class MethodPacker
    include Selectable::Object
    
    attr_accessor :methorig
    attr_accessor :aliaz
    attr_reader   :klass
    attr_reader   :meth
    attr_reader   :blk
    
    # * +k+ is a class
    # * +m+ is the name of an instance method in +k+
    # * +aliaz+ is an optional name for 
    #
    # This method makes the following changes to class +k+. 
    #
    # * Add a timeline attic to and include +Benelux+ 
    # * Rename the method to something like:
    #   __benelux_execute_2151884308_2165479316
    # * Install a new method with the name +m+.
    #
    def initialize(k,m,aliaz,&blk)
      Benelux.ld "%20s: %s#%s" % [self.class, k, m]
      if Benelux.packed_method? k, m
        raise SelectableError, "Already defined (#{k} #{m})"
      end
      @klass, @meth, @aliaz, @blk = k, m, aliaz, blk
      @aliaz ||= meth
      @klass.extend Attic  unless @klass.kind_of?(Attic)
      unless @klass.kind_of?(Benelux)
        @klass.attic :timeline
        @klass.send :include, Benelux
      end
      ## NOTE: This is commented out so we can include  
      ## Benelux definitions before all classes are loaded. 
      ##unless obj.respond_to? meth
      ##  raise NoMethodError, "undefined method `#{meth}' for #{obj}:Class"
      ##end
      thread_id, call_id = Thread.current.object_id.abs, @klass.object_id.abs
      @methorig = methorig = :"__benelux_#{@meth}_#{thread_id}_#{call_id}"
      Benelux.ld "%20s: %s" % ['Alias', @methorig] 
      
      @klass.module_eval do
        Benelux.ld [:def, self, m, 
          MethodPacker.method_defined?(self, m),
          MethodPacker.class_method_defined?(self, m)].inspect
        if MethodPacker.method_defined?(self, m)
          alias_method methorig, m  # Can't use the instance variables
        elsif MethodPacker.class_method_defined?(self, m)
          eval "class << self; alias #{methorig} #{m}; end"
        else
          raise BeneluxError, "No such method: #{self}.#{m}"
        end
      end
      install_method  # see generate_packed_method
      self.add_tags :class => @klass.to_s.to_sym, 
                    :meth  => @meth.to_sym,
                    :kind  => self.class.to_s.to_sym

      Benelux.packed_methods[@klass] ||= {}
      Benelux.packed_methods[@klass][@meth] = self
      Benelux.packed_methods[:all] ||= []
      Benelux.packed_methods[:all] << self
      
    end
    def self.method_defined?(klass, meth)
      meth &&= meth.to_s if RUBY_VERSION < "1.9"
      klass.method_defined?(meth) || 
      klass.private_method_defined?(meth) ||
      klass.protected_method_defined?(meth)
    end
    def self.class_method_defined?(klass, meth)
      meth &&= meth.to_s if RUBY_VERSION < "1.9"
      klass.singleton_methods.member? meth
    end
    def install_method
      raise "You need to implement this method"
    end
    # instance_exec for Ruby 1.8 written by Mauricio Fernandez
    # http://eigenclass.org/hiki/instance_exec
    if RUBY_VERSION =~ /1.8/
      module InstanceExecHelper; end
      include InstanceExecHelper
      def instance_exec(*args, &block) # !> method redefined; discarding old instance_exec
        mname = "__instance_exec_#{Thread.current.object_id.abs}_#{object_id.abs}"
        InstanceExecHelper.module_eval{ define_method(mname, &block) }
        begin
          ret = send(mname, *args)
        ensure
          InstanceExecHelper.module_eval{ undef_method(mname) } rescue nil
        end
        ret
      end
    end
    def run_block(*args)
      raise "must implement"
    end
  end
  
  class MethodTimer < MethodPacker
    # This method executes the method definition created by
    # generate_method. It calls <tt>@klass.module_eval</tt> 
    # with the modified line number (helpful for exceptions)
    def install_method
      @klass.module_eval generate_packed_method, __FILE__, 94
    end
    
    # Creates a method definition (for an eval). The 
    # method is named +@meth+ and it calls +@methorig+.
    #
    # The new method adds a Mark to the thread timeline
    # before and after +@alias+ is called. It also adds
    # a Range to the timeline based on the two marks. 
    def generate_packed_method
      %Q{
      def #{@meth}(*args, &block)
        #p ["#{@meth} 1"]
        call_id = "" << self.object_id.abs.to_s << args.object_id.abs.to_s
        Benelux.current_track :global unless Benelux.known_thread?
        mark_a = Benelux.current_track.timeline.add_mark :'#{@aliaz}_a'
        mark_a.add_tag :call_id => call_id
        tags = mark_a.tags
        ret = #{@methorig}(*args, &block)
        #p ["#{@meth} 2"]
        ret
      rescue => ex  # We do this so we can use
        raise ex    # ex in the ensure block.
      ensure
        mark_z = Benelux.current_track.timeline.add_mark :'#{@aliaz}_z'
        mark_z.tags = tags # In case tags were added between these marks
        range = Benelux.current_track.timeline.add_range :'#{@aliaz}', mark_a, mark_z
        range.exception = ex if defined?(ex) && !ex.nil?
      end
      }
    end
  end
  
  class MethodCounter < MethodPacker
    attr_reader :counter
    def install_method
      @klass.module_eval generate_packed_method, __FILE__, 122
    end
    
    def generate_packed_method(callblock=false)
      %Q{
      def #{@meth}(*args, &block)
        Benelux.current_track :global unless Benelux.known_thread?
        # Get a reference to this MethodCounter instance
        cmd = Benelux.packed_method #{@klass}, :#{@meth}
        ret = #{@methorig}(*args, &block)
        count = cmd.determine_count(args, ret)
        #Benelux.ld "COUNT(:#{@meth}): \#{count}"
        Benelux.current_track.timeline.add_count :'#{@meth}', count
        ret
      end
      }
    end
    
    def determine_count(args,ret)
      return 1 if @blk.nil?
      self.instance_exec args, ret, &blk
    end
    
  end
end