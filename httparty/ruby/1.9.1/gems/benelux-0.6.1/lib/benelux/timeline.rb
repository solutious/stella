
module Benelux
  # 
  #     |------+----+--+----+----|
  #            |
  #           0.02  
  #
  # Usage examples::
  #
  #    Benelux.timeline['9dbd521de4dfd6257135649d78a9c0aa2dd58cfe'].each do |mark|
  #      p [mark.track, mark.name, mark.tags[:usecase], mark.tags[:call_id]]
  #    end
  #
  #    Benelux.timeline.ranges(:do_request).each do |range|
  #      puts "Client%s: %s: %s: %f" % [range.track, range.thread_id, range.name, range.duration]
  #    end
  #
  #    regions = Benelux.timeline(track_id).regions(:execute)
  #
  class Timeline < Array
    include Selectable
    attr_accessor :ranges
    attr_accessor :stats
    attr_accessor :messages
    attr_accessor :default_tags
    attr_reader :caller
    def initialize(*args)
      @caller = Kernel.caller
      @ranges = SelectableArray.new
      @default_tags = Selectable::Tags.new
      @stats = Benelux::Stats.new
      @messages = SelectableArray.new
      add_default_tag :thread_id => Thread.current.object_id.abs
      super
    end
    def add_default_tags(tags=Selectable::Tags.new)
      @default_tags.merge! tags
    end
    alias_method :add_default_tag, :add_default_tags
    def remove_default_tags(*tags)
      @default_tags.delete_if { |n,v| tags.member?(n) }
    end
    alias_method :add_default_tag, :add_default_tags
    def track 
      @default_tags[:track]
    end
    
    def dump
       
    end
    
    def duration
      return 0 if self.last.nil?
      self.last - self.first
    end
    
    def each(*args, &blk)
      if args.empty? 
        super(&blk) 
      else 
        self.marks(*args).each(&blk)
      end
    end
    
    #
    #      obj.marks(:execute_a, :execute_z, :do_request_a) => 
    #          [:execute_a, :do_request_a, :do_request_a, :execute_z]
    #
    def marks(*names)
      return self if names.empty?
      names = names.flatten.collect { |n| n.to_s }
      self.select do |mark| 
        names.member? mark.name.to_s
      end
    end
    
    def [](*tags)
      tl = super
      tl.ranges = @ranges.select do |region|
        region.tags >= tags
      end
      stats = Benelux::Stats.new
      @stats.each do |stat|
        next unless stat.tags >= tags
        stats += stat
      end
      tl.messages = messages
      tl.stats = stats
      tl
    end
    
    #
    #     obj.ranges(:do_request) =>
    #         [[:do_request_a, :do_request_z], [:do_request_a, ...]]
    #    
    def ranges(name=nil, tags=Selectable::Tags.new)
      return @ranges if name.nil?
      @ranges.select do |range| 
        ret = name.to_s == range.name.to_s &&
        (tags.nil? || range.tags >= tags)
        ret
      end
    end
    
    #
    #     obj.regions(:do_request) =>
    #         
    #
    def regions(name=nil, tags=Selectable::Tags.new)
      return self if name.nil?
      self.ranges(name, tags).collect do |base_range|
        marks = self.sort.select do |mark|
          mark >= base_range.from && 
          mark <= base_range.to &&
          mark.tags >= base_range.tags
        end
        ranges = self.ranges.select do |range|
          range.from >= base_range.from &&
          range.to <= base_range.to &&
          range.tags >= base_range.tags
        end
        tl = Benelux::Timeline.new(marks)
        tl.ranges = ranges.sort
        tl
      end
    end
    
    def messages(tags=Selectable::Tags.new)
      ret = @messages.select do |msg| 
        (tags.nil? || msg.tags >= tags)
      end
      SelectableArray.new ret
    end
    
    def clear
      @ranges.clear
      @stats.clear
      @messages.clear
      super
    end
    
    # +msg+ is the message to store. This can be any type of
    # object that includes Selectable::Object (so that tags
    # can be added to the message to retreive it later). If
    # +msg+ does not include Selectable::Object it will be
    # converted to a TaggableString object.
    def add_message(msg, tags={})
      unless msg.kind_of?(Selectable::Object)
        msg = TaggableString.new msg.to_s
      end
      msg.add_tags self.default_tags
      msg.add_tags tags
      @messages << msg
      msg
    end
    
    def add_count(name, count, tags={})
      tags = tags.merge self.default_tags
      self.stats.add_group(name)
      self.stats.sample(name, count, tags)
      count
    end
    
    def add_mark(name)
      mark = Benelux::Mark.now(name)
      mark.add_tags self.default_tags
      self << mark
      mark
    end
    
    def add_range(name, from, to)
      range = Benelux::Range.new(name, from, to)
      range.add_tags self.default_tags
      range.add_tags from.tags
      range.add_tags to.tags
      self.ranges << range
      self.stats.add_group(name)
      self.stats.sample(name, range.duration, range.tags)
      range
    end
    
    def merge!(*timelines)
      timelines.each do |tl| 
        self.push *tl
        @ranges.push *tl.ranges
        @messages.push *tl.messages
        @stats += tl.stats
      end
      self
    end
    
    def +(other)
      self.push *other
      @ranges.push *other.ranges
      @messages.push *tl.messages
      @stats += other.stats
      self
    end
    # Needs to compare thread id and call id. 
    #def <=>(other)
    #end
  end
end