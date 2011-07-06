

module Benelux
  class Track
    attr_reader :name
    attr_reader :thread_group
    attr_reader :timeline
    attr_reader :rotated_timelines
    def initialize(n,t)
      @name, @thgrp = n, ThreadGroup.new
      @timeline = t || Benelux::Timeline.new
      @rotated_timelines = []
    end
    def add_thread(t=Thread.current)
      @thgrp.add t
      t
    end
    def threads
      @thgrp.list
    end
    def add_tags(args=Selectable::Tags.new)
      timeline.add_default_tags args
    end
    def remove_tags(*args)
      timeline.remove_default_tags *args
    end
    ##def rotate_timeline
    ##  self.rotated_timelines << self.timeline
    ##  tags = self.timeline.default_tags.clone
    ##  self.timeline = Benelux::Timeline.new
    ##  self.timeline.default_tags = tags
    ##  self.timeline
    ##end
  end
end