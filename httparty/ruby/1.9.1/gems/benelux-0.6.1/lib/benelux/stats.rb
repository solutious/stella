
module Benelux
  class Stats
    attr_reader :names
    
    def initialize(*names)
      @names = []
      add_groups names
    end
    def group(name)
      @names.member?(name) ? self.send(name) : create_zero_group(name)
    end
    def create_zero_group(name)
      g = Benelux::Stats::Group.new
      g.name = name
      g
    end
    def clear
      each { |g| g.clear }
      @names.clear
    end
    def size
      @names.size
    end
    # Each group
    def each(&blk)
      @names.each { |name| blk.call(group(name)) }
    end
    # Each group name, group
    def each_pair(&blk)
      @names.each { |name| blk.call(name, group(name)) }
    end
    def add_groups(*args)
      args.flatten.each do |meth|
        next if has_group? meth
        @names << meth
        self.class.send :attr_reader, meth
        (g = Benelux::Stats::Group.new).name = meth
        instance_variable_set("@#{meth}", g)
      end
    end
    def sample(name, s, tags={})
      self.send(name).sample(s, tags)
    end
    alias_method :add_group, :add_groups
    def has_group?(name)
      @names.member? name
    end
    def +(other)
      if !other.is_a?(Benelux::Stats)
        raise TypeError, "can't convert #{other.class} into Stats" 
      end
      s = self.clone
      other.names.each do |name|
        s.add_group name
        s.group(name) << other.group(name)
      end
      s
    end
    
    class Group < Array
      include Selectable
      
      attr_accessor :name
      
      def +(other)
        unless @name == other.name
          raise BeneluxError, "Cannot add #{other.name} to #{@name}"
        end
        g = Group.new self
        g.name = @name
        g << other
        g
      end
      
      def <<(other)
        self.push *other
        self
      end
      
      def merge(*tags)
        #tags = Selectable.normalize tags
        mc = Calculator.new
        mc.init_tags!
        all = tags.empty? ? self : self.filter(tags)
        all.each { |calc| 
          mc.merge! calc
          mc.add_tags_quick calc.tags
        }    
        mc
      end
      
      def sample(s, tags={})
        raise BeneluxError, "tags must be a Hash" unless Hash === tags
        c = Calculator.new
        c.add_tags tags
        c.sample s
        self << c
        nil
      end
      
      def tag_values(tag)
        vals = self.collect { |calc| calc.tags[tag] }
        Array.new vals.uniq
      end
      
      def tags()    merge.tags   end
      def mean()    merge.mean   end
      def min()     merge.min    end
      def max()     merge.max    end
      def sumsq()   merge.sumsq  end
      def sum()     merge.sum    end
      def sd()      merge.sd     end
      def n()       merge.n      end
      
      def filter(*tags)
        (f = super).name = @name
        f
      end
      alias_method :[], :filter
      
    end
    
    # Based on Mongrel::Stats, Copyright (c) 2005 Zed A. Shaw
    class Calculator < Storable
      include Selectable::Object
      
      field :mean => Float
      field :sd => Float
      field :sum => Float
      field :sumsq => Float
      field :n => Integer
      field :min => Float
      field :max => Float
      field :time => Float
      
      def initialize
        reset
      end
  
      def +(other)
        c = Calculator.new
        c.merge! self
        c.merge! other
        c
      end
  
      # Resets the internal counters so you can start sampling again.
      def reset
        @n, @sum, @sumsq = 0.0, 0.0, 0.0
        @min, @max = 0.0, 0.0
      end
      
      def samples(*args)  
        args.flatten.each { |s| sample(s) }
      end
      
      def merge!(other)
        return self if other.n == 0
        if @n == 0
          @min, @max = other.min, other.max
        else
          @min = other.min if other.min < @min
          @max = other.max if other.max > @max
        end
        @sum += other.sum
        @sumsq += other.sumsq
        @n += other.n
        self
      end
      
      # Adds a sampling to the calculations.
      def sample(s)
        @sum += s
        @sumsq += s * s
        if @n == 0
          @min = @max = s
        else
          @min = s if @min > s
          @max = s if @max < s
        end
        @n+=1
      end
      
      def first_tick() @last_time = Time.now end
      def tick
        tick_time = Time.now
        sample(tick_time - @last_time)
        @last_time = tick_time
      end
      
      # Dump this Stats object with an optional additional message.
      def dump(msg = "", out=STDERR)
        out.puts "#{msg}: #{self.report}"
      end

      # Returns a common display (used by dump)
      def report
        v = [mean, @n, @sum, @sumsq, sd, @min, @max]
        t = %q'%8d(N) %10.4f(SUM) %8.4f(SUMSQ) %8.4f(SD) %8.4f(MIN) %8.4f(MAX)'
        ('%0.4f: ' << t) % v
      end
      
      def inspect
        v = [ mean, @n, @sum, @sumsq, sd, @min, @max, tags]
        "%.4f: n=%.4f sum=%.4f sumsq=%.4f sd=%.4f min=%.4f max=%.4f %s" % v
      end
      
      def to_s; mean.to_s; end
      def to_f; mean.to_f; end
      def to_i; mean.to_i; end
  
      # NOTE: This is an alias for average. We don't store values
      # so we can't return the actual mean
      def mean;    avg() end
      def average; avg() end
      # Calculates and returns the mean for the data passed so far.
      def avg; return 0.0 unless @n > 0; @sum / @n; end
      
      # Calculates the standard deviation of the data so far.
      def sd
        return 0.0 if @n <= 1
        # (sqrt( ((s).sumsq - ( (s).sum * (s).sum / (s).n)) / ((s).n-1) ))
        begin
          return Math.sqrt( (@sumsq - (@sum * @sum / @n)) / (@n-1) )
        rescue Errno::EDOM
          return 0.0
        end
      end
      
      def ==(other)
        return false unless self.class == other.class
        a=([@sum, @min, @max, @n, @sumsq] - 
           [other.sum, other.min, other.max, other.n, other.sumsq])
        a.empty?
      end
      
    end
    
    
  end
end