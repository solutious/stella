
# = Selectable
#
# <strong>Note: Classes that include Selectable must also
# subclass Array</strong>
#
#     class Something < Array
#       include Selectable
#     end
#
module Selectable
  
  class SelectableError < RuntimeError; end
  class TagsNotInitialized < SelectableError; end
  
  require 'selectable/tags'
  require 'selectable/object'
  
  # Returns a Hash or Array
  def Selectable.normalize(*tags)
    tags.flatten!
    tags = tags.first if tags.first.kind_of?(Hash) || tags.first.kind_of?(Array)
    # NOTE: The string enforcement is disabled 
    # FOR NOW.
    #if tags.is_a?(Hash)
    #  #tmp = {}
    #  #tags.each_pair { |n,v| tmp[n] = v.to_s }
    #  #tags = tmp
    #else
    #  tags.collect! { |v| v.to_s }
    #end
    tags
  end
  
  # Return the objects that match the given tags. 
  # This process is optimized for speed so there
  # as few conditions as possible. One result of
  # that decision is that it does not gracefully 
  # handle error conditions. For example, if the
  # tags in an object have not been initialized,
  # you will see this error:
  #
  #     undefined method `>=' for nil:NilClass
  #
  # It also means you need be aware of the types
  # of objects you are storing as values. If you
  # store a Symbol, you must send a Symbol here.
  def filter(*tags)
    tags = Selectable.normalize tags
    # select returns an Array. We want a Selectable.
    items = self.select { |obj| obj.tags >= tags }
    self.class.new items
  end  
  
  # Reverse filter. 
  def rfilter(*tags)
    tags = Selectable.normalize tags
    # select returns an Array. We want a Selectable.
    items = self.select { |obj| obj.tags < tags }
    self.class.new items
  end
  
  def filter!(*tags)
    tags = Selectable.normalize tags
    self.delete_if { |obj|   obj.tags < tags }
  end
  
  def tags
    t = Selectable::Tags.new
    self.each { |o| t.merge o.tags }
    t
  end
  
  # Creates an alias for +filter+ called +[]+, but 
  # only if [] doesn't already exist in +obj+.
  def self.included(obj)
    alias_method :[], :filter unless obj.method_defined? :[]
  end
end

class SelectableArray < Array
  include Selectable
end
class SelectableHash < Hash
  include Selectable
end

class TaggableString < String
  include Selectable::Object
  def initialize(str, tags={})
    super(str)
    add_tags tags unless tags.empty?
  end
end
