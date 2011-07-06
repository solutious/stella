# $ ruby tryouts/metaclasses.rb

class Object
  
  # A convenient method for getting the metaclass of the current object.
  # i.e.
  #
  #     class << self; self; end;
  #
  def metaclass; class << self; self; end; end

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

# Create an instance method
class NamedArray1
  class_eval do
    define_method(:name) do
      :roger
    end
  end
end
p [1, NamedArray1.new.name]

# Create getter and setter instance methods
class NamedArray2
  class_eval do
    define_method(:name) do
      instance_variable_get("@name")
    end
    define_method(:name=) do |val|
      instance_variable_set("@name", val)
    end
  end
end
a = NamedArray2.new
a.name = :roger
p [2, a.name, a.instance_variables]

# Create getter and setter instance methods,
# store instance variable in metaclass
class NamedArray3
  class_eval do
    define_method(:name) do
      metaclass.instance_variable_get("@name")
    end
    define_method(:name=) do |val|
      metaclass.instance_variable_set("@name", val)
    end
  end
end
a = NamedArray3.new
a.name = :roger
p [3, a.name, a.instance_variables, a.metaclass.instance_variables]

# Create a module with the which puts the functionality 
# in NamedArray3 into a class method. 
module StorageArea
  def store *junk
    junk.each do |name|
      class_eval do
        define_method(name) do
          metaclass.instance_variable_get("@#{name}")
        end
        define_method("#{name}=") do |val|
          metaclass.instance_variable_set("@#{name}", val)
        end
      end
    end
  end
end
class NamedArray4
  extend StorageArea
  store :name
end
a = NamedArray4.new
a.name = :roger
p [4, a.name, a.instance_variables, a.metaclass.instance_variables]





