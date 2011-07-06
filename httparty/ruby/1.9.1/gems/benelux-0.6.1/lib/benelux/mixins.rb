


class Object 
  def hex_object_id
    prefix = RUBY_VERSION >= '1.9' ? '0x00000' : '0x'
    "%s%x" % [prefix, (self.object_id.abs << 1)]
  end
  alias hexoid hex_object_id
end



#if RUBY_VERSION =~ /1.8/
  class Symbol
    def <=>(other)
      self.to_s <=> other.to_s
    end
  end
#end



class Thread
  extend Attic
  send :attr_accessor, :timeline
  send :attr_accessor, :track_name
  send :attr_accessor, :rotated_timelines
  def rotate_timeline
    self.rotated_timelines << self.timeline
    tags = self.timeline.default_tags.clone
    self.timeline = Benelux::Timeline.new
    self.timeline.default_tags = tags
    self.timeline
  end
end
