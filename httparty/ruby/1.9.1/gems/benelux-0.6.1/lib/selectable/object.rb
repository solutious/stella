
module Selectable
  
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

end