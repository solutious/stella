
class NoMetaClass < RuntimeError
end

# = Object
#
# These methods are copied directly from _why's metaid.rb. 
# See: http://whytheluckystiff.net/articles/seeingMetaclassesClearly.html
class Object
  
  unless defined?(::Object::NOMETACLASS)
    # An Array of classes which do not have metaclasses.
    NOMETACLASS = [Symbol, Fixnum].freeze
  end
  
  def nometaclass?
    NOMETACLASS.member?(self)
  end
  
  def metaclass?
    !NOMETACLASS.member?(self.class)
  end
  
  # A convenient method for getting the metaclass of the current object.
  # i.e.
  #
  #     class << self; self; end;
  #
  # NOTE: Some Ruby class do not have meta classes (see: NOMETACLASS). 
  # For these classes, this method returns the class itself. That means
  # the instance variables will stored in the class itself. 
  def metaclass
    if !self.metaclass?
      raise NoMetaClass, self
    else
      class << self; self; end; 
    end
  end
  
  # Execute a block +&blk+ within the metaclass of the current object.
  def meta_eval &blk; metaclass.instance_eval &blk; end
  
  # Add an instance method called +name+ to metaclass for the current object.
  # This is useful because it will be available as a singleton method
  # to all subclasses too. 
  def meta_def name, &blk
    meta_eval { define_method name, &blk }
  end
  
  # Add a class method called +name+ for the current object's class. This
  # isn't so special but it maintains consistency with meta_def. 
  def class_def name, &blk
    class_eval { define_method name, &blk }
  end

  
  # A convenient method for getting the metaclass of the metaclass
  # i.e.
  #
  #     self.metaclass.metaclass
  #
  def metametaclass; self.metaclass.metaclass; end

  def metameta_eval &blk; metametaclass.instance_eval &blk; end

  def metameta_def name, &blk
    metameta_eval { define_method name, &blk }
  end
  
end



# = Attic
#
# A place to store instance variables. 
#
module Attic
  VERSION = '0.5.3' unless defined?(VERSION)
  
  module InstanceMethods
    def attic_variables
      self.class.attic_variables
    end
    alias_method :attic_vars, :attic_variables
    def attic_variable? n
      self.class.attic_variable? n
    end
    def attic_variable_set(n,v)
      attic_variables << n unless attic_variable? n
      if metaclass?
        metaclass.instance_variable_set("@#{n}", v)
      else
        instance_variable_set("@___attic_#{n}", v)
      end
    end
    def attic_variable_get(n)
      if metaclass?
        metaclass.instance_variable_get("@#{n}")
      else
        instance_variable_get("@___attic_#{n}")
      end
    end
  end
  
  def self.included(o)
    raise "You probably meant to 'extend Attic' in #{o}"
  end
  
  def self.extended(o)
    # This class has already been extended. 
    return if o.ancestors.member? Attic::InstanceMethods
    
    
    ## NOTE: This is just a reminder for a more descerning way to 
    ## include the meta methods, instead of using a global mixin. 
    ##o.class_eval do
    ##  include ObjectHelpers
    ##end
    # Create an instance method that returns the attic variables. 
    o.send :include, Attic::InstanceMethods
    #p [:extend, self, o]
    
    o.metaclass.instance_variable_set("@attic_variables", [])
    o.class_eval do
      def self.inherited(o2)
        #p [:inherit, self, o2]
        attic_vars = self.attic_variables.clone
        o2.metaclass.instance_variable_set("@attic_variables", attic_vars)
      end
      if method_defined? :instance_variables
        old_instance_variables = instance_method(:instance_variables)
        define_method :instance_variables do
          ret = old_instance_variables.bind(self).call.clone
          ret.reject! { |v| v.to_s =~ /^@___?attic/ }  # match 2 or 3 underscores
          ret
        end
        define_method :all_instance_variables do
          old_instance_variables.bind(self).call
        end
      end
    end
  
    
  end
  
  
  # A class method for defining variables to store in the attic. 
  # * +junk+ is a list of variables names. Accessor methods are 
  #   created for each variable name in the list. 
  # 
  # Returns the list of attic variable names or if not junk was
  # given, returns the metaclass. 
  #
  # e.g.
  #  
  #     String.extend Attic
  #     String.attic :timestamp
  #
  # In this example, attic created two instance methods:
  # * <tt>String#timestamp</tt> for getting the value
  # * <tt>String#timestamp</tt> for setting the value
  #
  def attic *junk
    return metaclass if junk.empty?
    junk.each do |name|
      next if attic_variable? name
      self.attic_variables << name
      
      unless method_defined? name
        define_method(name) do
          attic_variable_get name
        end
      end
      unless method_defined? "#{name}="
        define_method("#{name}=") do |val|
          attic_variable_set name, val
        end
      end
    end
    attic_vars
  end
  
  # Returns an Array of attic variables for the current class. 
  # e.g.
  #
  #     String.extend Attic
  #     String.attic :timestamp
  #     String.attic_variables     # => [:timestamp]
  #
  def attic_variables
    a = self.metaclass.instance_variable_get("@attic_variables")
    a ||= self.metaclass.instance_variable_set("@attic_variables", [])
    a
  end
  alias_method :attic_vars, :attic_variables

  def attic_variable?(n)
    attic_variables.member? n
  end
  
end

# - Module#instance_method returns an UnboundMethod
#   - http://ruby-doc.org/core/classes/Module.html#M001659
