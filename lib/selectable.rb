
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
  
  
  # An example of filtering an Array of tagged objects based
  # on a provided Hash of tags or Array of tag values. +obj+
  # in this case would be an object that includes Taggable.
  #
  #     class Something
  #       def [](tags={})
  #         tags = [tags].flatten unless tags.is_a?(Hash)
  #         self.select do |obj|
  #           obj.tags >= tags
  #         end
  #       end
  #     end
  #
  class Tags < ::Hash
    
    def to_s
      tagstr = []
      self.each_pair do |n,v|
        tagstr << "%s=%s" % [n,v]
      end
      tagstr.join ' '
    end
    
    def inspect
      to_s
    end
    
    def ==(other)
      if other.is_a?(Array)
        # NOTE: This resolves the issue of sorting an Array
        # with a mix of Object types (Integers, Strings, Symbols).
        # As in: self.values.sort == other.sort)
        (self.values.size == other.size) &&
        (self.values - other).empty?
      else
        super(other)
      end
    end
    
    # Comparison between other Hash and Array objects.
    #
    # e.g.
    #
    #     a = {:a => 1, :b => 2}
    #     a > {:a => 1, :b => 2, :c => 3}    # => false
    #     a > {:a => 1}                      # => true
    #     a < {:a => 1, :b => 2, :c => 3}    # => true
    #     a >= [2, 1]                        # => true
    #     a > [2, 1]                         # => false
    #
    def <=>(b)
      return 0 if self == b
      self.send :"compare_#{b.class}", b
    end
        
    def >(other)  (self <=> other)  > 0 end
    def <(other)  (self <=> other)  < 0 end
    
    def <=(other) (self <=> other) <= 0 end
    def >=(other) (self <=> other) >= 0 end
    
    private
    
    def compare_Hash(b)
      a = self
      return -1 unless (a.values_at(*b.keys) & b.values).size >= b.size
      1
    end
    alias_method :"compare_Selectable::Tags", :compare_Hash
    
    def compare_Array(b)
      return -1 unless (self.values & b).size >= b.size
      1
    end
    
    def method_missing(meth, *args)
      raise SelectableError, "#{meth}: #{args.first} is not a Hash or Array"
    end
    
    ## NOTE: This is helpful but defensive. Ponder!
    ##def compare_forced_array(b)
    ##  compare_Array([b])
    ##end
    ##alias_method :compare_String, :compare_forced_array
    ##alias_method :compare_Symbol, :compare_forced_array
    ##alias_method :compare_Fixnum, :compare_forced_array
      
  end


  # Helper methods for objects with a @tags instance var
  #
  # e.g. 
  #
  #     class Something
  #       include Selectable::Object
  #     end
  #
  module Object
    attr_accessor :tags
    def add_tags(tags)
      init_tags!
      @tags.merge! tags
    end
    alias_method :add_tag, :add_tags
    def add_tags_quick(tags)
      @tags.merge! tags
    end
    alias_method :add_tag_quick, :add_tags_quick
    def remove_tags(*tags)
      raise TagsNotInitialized if @tags.nil?
      tags.flatten!
      @tags.delete_if { |n,v| tags.member?(n) }
    end
    alias_method :remove_tag, :remove_tags
    def tag_values(*tags)
      raise TagsNotInitialized if @tags.nil?
      tags.flatten!
      ret = @tags.collect { |n,v| 
        v if tags.empty? || tags.member?(n) 
      }.compact
      ret
    end
    def init_tags!
      @tags ||= Selectable::Tags.new
    end
  end
  
  
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
    add_tags tags
  end
end
