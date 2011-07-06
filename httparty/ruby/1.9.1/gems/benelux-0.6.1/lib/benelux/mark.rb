module Benelux
  class Mark < Time
    include Selectable::Object
    attr_accessor :name
    def self.now(n=nil)
      v = super()
      v.tags = Selectable::Tags.new
      v.name = n 
      v
    end
    def track 
      @tags[:track]
    end
    def inspect(reftime=nil)
      val = reftime.nil? ? self : (reftime - self)
      "#<%s:%s at=%f name=%s %s>" % [self.class, hexoid, to_f, name, tags]
    end
    def to_s(reftime=nil)
      val = reftime.nil? ? self : (reftime - self)
      val.to_f.to_s
    end
    def distance(time)
      self - time
    end
    def ==(other)
      self.name == other.name &&
      self.tags == other.tags &&
      self.to_f == self.to_f
    end
  end
end