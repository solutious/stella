

# Caesars -- Rapid DSL prototyping in Ruby.
#
# Subclass Caesars and start drinking! I mean, start prototyping
# your own domain specific language!
#
# See bin/example
#
class Caesars

  require 'caesars/orderedhash'
  require 'caesars/exceptions'
  require 'caesars/config'

  VERSION = "0.7.4"

  @@debug = false
  @@chilled = {}
  @@forced_array = {}
  @@forced_ignore = {}
  @@known_symbols = []
  @@known_symbols_by_glass = {}
  
  HASH_TYPE = (RUBY_VERSION =~ /1.9/) ? ::Hash : Caesars::OrderedHash
  DIGEST_TYPE = Digest::SHA1
  
  require 'caesars/hash'
    
  def Caesars.enable_debug; @@debug = true; end
  def Caesars.disable_debug; @@debug = false; end
  def Caesars.debug?; @@debug; end
  # Is the given +name+ chilled? 
  # See Caesars.chill
  def Caesars.chilled?(name)
    return false unless name
    @@chilled.has_key?(name.to_sym)
  end
  # Is the given +name+ a forced array? 
  # See Caesars.forced_array
  def Caesars.forced_array?(name)
    return false unless name
    @@forced_array.has_key?(name.to_sym)
  end
  # Is the given +name+ a forced ignore? 
  # See Caesars.forced_ignore
  def Caesars.forced_ignore?(name)
    return false unless name
    @@forced_ignore.has_key?(name.to_sym)
  end
  
  # Add +s+ to the list of global symbols (across all instances of Caesars)
  def Caesars.add_known_symbol(g, s)
    g = Caesars.glass(g)
    STDERR.puts "add_symbol: #{g} => #{s}" if Caesars.debug?
    @@known_symbols << s.to_sym
    @@known_symbols_by_glass[g] ||= []
    @@known_symbols_by_glass[g] << s.to_sym
  end
  
  # Is +s+ in the global keyword list? (accross all instances of Caesars)
  def Caesars.known_symbol?(s); @@known_symbols.member?(s.to_sym); end
  # Is +s+ in the keyword list for glass +g+?
  def Caesars.known_symbol_by_glass?(g, s)
    g &&= g.to_sym
    @@known_symbols_by_glass[g] ||= []
   @@known_symbols_by_glass[g].member?(s.to_sym)
  end
    
    # An instance of Caesars::Hash which contains the data specified by your DSL
  attr_accessor :caesars_properties
  
  def initialize(name=nil)
    @caesars_name = name if name
    @caesars_properties = Caesars::Hash.new
    @caesars_pointer = @caesars_properties
    init if respond_to?(:init)
  end
  
  # Returns an array of the available top-level attributes
  def keys; @caesars_properties.keys; end
  
  # Returns the parsed tree as a regular hash (instead of a Caesars::Hash)
  def to_hash; @caesars_properties.to_hash; end
  
  # DEPRECATED -- use find_deferred
  #
  # Look for an attribute, bubbling up to the parent if it's not found
  # +criteria+ is an array of attribute names, orders according to their
  # relationship. The last element is considered to the desired attribute.
  # It can be an array.
  #
  #      # Looking for 'attribute'. 
  #      # First checks at @caesars_properties[grandparent][parent][attribute]
  #      # Then, @caesars_properties[grandparent][attribute]
  #      # Finally, @caesars_properties[attribute]
  #      find_deferred('grandparent', 'parent', 'attribute')
  #
  # Returns the attribute if found or nil.
  #
  def find_deferred_old(*criteria)
    # This is a nasty implementation. Sorry me! I'll enjoy a few
    # caesars and be right with you. 
    att = criteria.pop
    val = nil
    while !criteria.empty?
      p [criteria, att].flatten if Caesars.debug?
      val = find(criteria, att)
      break if val
      criteria.pop
    end
    # One last try in the root namespace
    val = @caesars_properties[att.to_sym] if defined?(@caesars_properties[att.to_sym]) && !val
    val
  end
  
  # Look for an attribute, bubbling up through the parents until it's found.
  # +criteria+ is an array of hierarchical attributes, ordered according to 
  # their relationship. The last element is the desired attribute to find.
  # Looking for 'ami':
  #
  #      find_deferred(:environment, :role, :ami)
  #
  # First checks at @caesars_properties[:environment][:role][:ami]
  # Then, @caesars_properties[:environment][:ami]
  # Finally, @caesars_properties[:ami]
  #
  # If the last element is an Array, it's assumed that only that combination
  # should be returned.
  # 
  #      find_deferred(:environment, :role:, [:disks, '/file/path'])
  # 
  # Search order:
  # * [:environment][:role][:disks]['/file/path']
  # * [:environment][:disks]['/file/path']
  # * [:disks]['/file/path']
  #
  # Other nested Arrays are treated special too. We look at the criteria from
  # right to left and remove the first nested element we find.
  #
  #      find_deferred([:region, :zone], :environment, :role, :ami)
  #
  # Search order:
  # * [:region][:zone][:environment][:role][:ami]
  # * [:region][:environment][:role][:ami]
  # * [:environment][:role][:ami]
  # * [:environment][:ami]
  # * [:ami]
  #
  # NOTE: There is a maximum depth of 10. 
  #
  # Returns the attribute if found or nil.
  #
  def find_deferred(*criteria)
    
    # The last element is assumed to be the attribute we're looking for. 
    # The purpose of this function is to bubble up the hierarchy of a
    # hash to find it.
    att = criteria.pop  
    
    # Account for everything being sent as an Array
    # i.e. find([1, 2, :attribute])
    # We don't use flatten b/c we don't want to disturb nested Arrays
    if criteria.empty?
      criteria = att
      att = criteria.pop
    end
    
    found = nil
    sacrifice = nil
    
    while !criteria.empty?
      found = find(criteria, att)
      break if found

      # Nested Arrays are treated special. We look at the criteria from
      # right to left and remove the first nested element we find.
      #
      # i.e. [['a', 'b'], 1, 2, [:first, :second], :attribute]
      #
      # In this example, :second will be removed first.
      criteria.reverse.each_with_index do |el,index|
        next unless el.is_a?(Array)    # Ignore regular criteria
        next if el.empty?              # Ignore empty nested hashes
        sacrifice = el.pop
        break
      end

      # Remove empty nested Arrays
      criteria.delete_if { |el| el.is_a?(Array) && el.empty? }

      # We need to make a sacrifice
      sacrifice = criteria.pop if sacrifice.nil?
      break if (limit ||= 0) > 10  # A failsafe
      limit += 1
      sacrifice = nil
    end

    found || find(att)  # One last try in the root namespace
  end
  
  # Looks for the specific attribute specified. 
  # +criteria+ is an array of attribute names, orders according to their
  # relationship. The last element is considered to the desired attribute.
  # It can be an array.
  #
  # Unlike find_deferred, it will return only the value specified, otherwise nil. 
  def find(*criteria)
    criteria.flatten! if criteria.first.is_a?(Array)
    p criteria if Caesars.debug?
    # BUG: Attributes can be stored as strings and here we only look for symbols
    str = criteria.collect { |v| "[:'#{v}']" if v }.join
    eval_str = "@caesars_properties#{str} if defined?(@caesars_properties#{str})"
    val = eval eval_str
    val
  end
  
  # Act a bit like a hash for the case:
  # @subclass[:property]
  def [](name)
    return @caesars_properties[name] if @caesars_properties.has_key?(name)
    return @caesars_properties[name.to_sym] if @caesars_properties.has_key?(name.to_sym)
  end
  
  # Act a bit like a hash for the case:
  # @subclass[:property] = value
  def []=(name, value)
    @caesars_properties[name] = value
  end
  
  # Add +keyword+ to the list of known symbols for this instances
  # as well as to the master known symbols list. See: known_symbol?
  def add_known_symbol(s)
    @@known_symbols << s.to_sym
    @@known_symbols_by_glass[glass] ||= []
    @@known_symbols_by_glass[glass] << s.to_sym
  end  
  
  # Has +s+ already appeared as a keyword in the DSL for this glass type?
  def known_symbol?(s)
    @@known_symbols_by_glass[glass] && @@known_symbols_by_glass[glass].member?(s)
  end
  
  # Returns the lowercase name of the class. i.e. Some::Taste  # => taste
  def glass; @glass ||= (self.class.to_s.split(/::/)).last.downcase.to_sym; end
  
  # Returns the lowercase name of +klass+. i.e. Some::Taste  # => taste
  def self.glass(klass); (klass.to_s.split(/::/)).last.downcase.to_sym; end
  
  # This method handles all of the attributes that are not forced hashes
  # It's used in the DSL for handling attributes dyanamically (that weren't defined
  # previously) and also in subclasses of Caesars for returning the appropriate
  # attribute values. 
  def method_missing(meth, *args, &b)
    STDERR.puts "Caesars.method_missing: #{meth}" if Caesars.debug?
    add_known_symbol(meth)
    if Caesars.forced_ignore?(meth)
      STDERR.puts "Forced ignore: #{meth}" if Caesars.debug?
      return
    end
    
    # Handle the setter, attribute=
    if meth.to_s =~ /=$/ && @caesars_properties.has_key?(meth.to_s.chop.to_sym)
      return @caesars_properties[meth.to_s.chop.to_sym] = (args.size == 1) ? args.first : args
    end
    
    return @caesars_properties[meth] if @caesars_properties.has_key?(meth) && args.empty? && b.nil?
    
    # We there are no args and no block, we return nil. This is useful
    # for calls to methods on a Caesars::Hash object that don't have a
    # value (so we cam treat self[:someval] the same as self.someval).
    if args.empty? && b.nil?
      
      # We make an exception for methods that we are already expecting. 
      if Caesars.forced_array?(meth)
        return @caesars_pointer[meth] ||= Caesars::Hash.new
      else
        return nil 
      end
    end
    
    if b
      if Caesars.forced_array?(meth)
        @caesars_pointer[meth] ||= []
        args << b  # Forced array blocks are always chilled and at the end
        @caesars_pointer[meth] << args
      else
        # We loop through each of the arguments sent to "meth". 
        # Elements are added for each of the arguments and the
        # contents of the block will be applied to each one. 
        # This is an important feature for Rudy configs since
        # it allows defining several environments, roles, etc
        # at the same time.
        #     env :dev, :stage, :prod do
        #       ...
        #     end
        
        # Use the name of the method if no name is supplied. 
        args << meth if args.empty?
        
        args.each do |name|
          prev = @caesars_pointer
          @caesars_pointer[name] ||= Caesars::Hash.new
          if Caesars.chilled?(meth)
            @caesars_pointer[name] = b
          else
            @caesars_pointer = @caesars_pointer[name]
            begin
              b.call if b
            rescue ArgumentError, SyntaxError => ex
              STDERR.puts "CAESARS: error in #{meth} (#{args.join(', ')})" 
              raise ex
            end
            @caesars_pointer = prev
          end
        end
      end
      
    # We've seen this attribute before, add the value to the existing element    
    elsif @caesars_pointer.kind_of?(Hash) && @caesars_pointer[meth]
      
      if Caesars.forced_array?(meth)
        @caesars_pointer[meth] ||= []
        @caesars_pointer[meth] << args
      else
        # Make the element an Array once there's more than a single value
        unless @caesars_pointer[meth].is_a?(Array)
          @caesars_pointer[meth] = [@caesars_pointer[meth]] 
        end
        @caesars_pointer[meth] += args
      end
      
    elsif !args.empty?
      if Caesars.forced_array?(meth)
        @caesars_pointer[meth] = [args]
      else
        @caesars_pointer[meth] = args.size == 1 ? args.first : args
      end
    end
  
  end
  
  
  # Force the specified keyword to always be treated as a hash. 
  # Example:
  #
  #     startup do
  #       disks do
  #         create "/path/2"         # Available as hash: [action][disks][create][/path/2] == {}
  #         create "/path/4" do      # Available as hash: [action][disks][create][/path/4] == {size => 14}
  #           size 14
  #         end
  #       end
  #     end
  #
  def self.forced_hash(caesars_meth, &b)
    STDERR.puts "forced_hash: #{caesars_meth}" if Caesars.debug?
    Caesars.add_known_symbol(self, caesars_meth)
    module_eval %Q{
      def #{caesars_meth}(*caesars_names,&b)
        this_meth = :'#{caesars_meth}'
        
        add_known_symbol(this_meth)
        if Caesars.forced_ignore?(this_meth)
          STDERR.puts "Forced ignore: \#{this_meth}" if Caesars.debug?
          return
        end
        
        if @caesars_properties.has_key?(this_meth) && caesars_names.empty? && b.nil?
          return @caesars_properties[this_meth] 
        end
        
        return nil if caesars_names.empty? && b.nil?
        return method_missing(this_meth, *caesars_names, &b) if caesars_names.empty?
        
        # Take the first argument in the list provided to "caesars_meth"
        caesars_name = caesars_names.shift
        
        prev = @caesars_pointer
        @caesars_pointer[this_meth] ||= Caesars::Hash.new
        
        hash = Caesars::Hash.new
        if @caesars_pointer[this_meth].has_key?(caesars_name)
          STDERR.puts "duplicate key ignored: \#{caesars_name}"
          return
        end
        
        # The pointer is pointing to the hash that contains "this_meth". 
        # We wan't to make it point to the this_meth hash so when we call 
        # the block, we'll create new entries in there. 
        @caesars_pointer = hash  
        
        if Caesars.chilled?(this_meth)
          # We're done processing this_meth so we want to return the pointer
          # to the level above. 
          @caesars_pointer = prev
          @caesars_pointer[this_meth][caesars_name] = b
        else          
          if b
            # Since the pointer is pointing to the this_meth hash, all keys
            # created in the block we be placed inside. 
            b.call 
          end
           # We're done processing this_meth so we want to return the pointer
           # to the level above. 
           @caesars_pointer = prev
           @caesars_pointer[this_meth][caesars_name] = hash
        end

        # All other arguments provided to "caesars_meth" 
        # will reference the value for the first argument. 
        caesars_names.each do |name|
          @caesars_pointer[this_meth][name] = @caesars_pointer[this_meth][caesars_name]
        end
         
        @caesars_pointer = prev   # Make sure we're back up one level
      end
    }
    nil
  end
  
  # Specify a method that should delay execution of its block. 
  # Here's an example:
  # 
  #      class Food < Caesars
  #        chill :count
  #      end
  #      
  #      food do
  #        taste :delicious
  #        count do |items|
  #          puts items + 2
  #        end
  #      end
  #
  #      @food.count.call(3)    # => 5
  #
  def self.chill(caesars_meth)
    STDERR.puts "chill: #{caesars_meth}" if Caesars.debug?
    Caesars.add_known_symbol(self, caesars_meth)
    @@chilled[caesars_meth.to_sym] = true
    nil
  end
  
  # Specify a method that should store it's args as nested Arrays
  # Here's an example:
  #
  #      class Food < Caesars
  #        forced_array :sauce
  #      end
  #      
  #      food do
  #        taste :delicious
  #        sauce :tabasco, :worcester
  #        sauce :franks
  #      end
  #
  #      @food.sauce            # => [[:tabasco, :worcester], [:franks]]
  #
  # The blocks for elements that are specified as forced_array
  # will be chilled (stored as Proc objects). The block is put
  # at the end of the Array. e.g.
  #
  #     food do
  #       sauce :arg1, :arg2 do
  #         ...
  #       end
  #     end
  #
  #     @food.sauce             # => [[:inline_method, :arg1, :arg2, #<Proc:0x1fa552>]]
  #
  def self.forced_array(caesars_meth)
    STDERR.puts "forced_array: #{caesars_meth}" if Caesars.debug?
    Caesars.add_known_symbol(self, caesars_meth)
    @@forced_array[caesars_meth.to_sym] = true
    nil
  end
  
  # Specify a method that should always be ignored. 
  # Here's an example:
  #
  #     class Food < Caesars
  #       forced_ignore :taste
  #     end
  #     
  #     food do
  #       taste :delicious
  #     end
  #
  #     @food.taste             # => nil
  #
  def self.forced_ignore(caesars_meth)
    STDERR.puts "forced_ignore: #{caesars_meth}" if Caesars.debug?
    Caesars.add_known_symbol(self, caesars_meth)
    @@forced_ignore[caesars_meth.to_sym] = true
    nil
  end
  
  # Executes automatically when Caesars is subclassed. This creates the
  # YourClass::DSL module which contains a single method named after YourClass 
  # that is used to catch the top level DSL method. 
  #
  # For example, if your class is called Glasses::HighBall, your top level method
  # would be: highball.
  #
  #      highball :mine do
  #        volume "9oz"
  #      end
  #
  def self.inherited(modname)
    STDERR.puts "INHERITED: #{modname}" if Caesars.debug?
    
    # NOTE: We may be able to replace this without an eval using Module.nesting
    meth = (modname.to_s.split(/::/)).last.downcase  # Some::HighBall => highball
    
    # The method name "meth" is now a known symbol 
    # for the short class name (also "meth").
    Caesars.add_known_symbol(meth, meth)
    
    # We execute a module_eval form the namespace of the inherited class  
    # so when we define the new module DSL it will be Some::HighBall::DSL.
    modname.module_eval %Q{
      module DSL
        def #{meth}(*args, &b)
          name = !args.empty? ? args.first.to_s : nil
          varname = "@#{meth.to_s}"
          varname << "_\#{name}" if name
          inst = instance_variable_get(varname)
          
          # When the top level DSL method is called without a block
          # it will return the appropriate instance variable name
          return inst if b.nil?
          
          # Add to existing instance, if it exists. Otherwise create one anew.
          # NOTE: Module.nesting[1] == modname (e.g. Some::HighBall)
          inst = instance_variable_set(varname, inst || Module.nesting[1].new(name))
          inst.instance_eval(&b)
          inst
        end
        
        def self.methname
          :"#{meth}"
        end
        
      end
    }, __FILE__, __LINE__
    
  end
  
end
  
  

