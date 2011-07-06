require 'attic'
require 'thread'
require 'thwait'
require 'selectable'
require 'storable'

module Benelux
  VERSION = "0.6.1"
  NOTSUPPORTED = [Class, Object, Kernel]
  
  class BeneluxError < RuntimeError; end
  class NotSupported < BeneluxError; end
  class AlreadyTimed < BeneluxError; end
  class UnknownTrack < BeneluxError; end
  class BadRecursion < BeneluxError; end
  
  require 'benelux/mark'
  require 'benelux/track'
  require 'benelux/range'
  require 'benelux/stats'
  require 'benelux/mixins'
  require 'benelux/packer'
  require 'benelux/timeline'
  
  @packed_methods = {}
  class << self
    attr_reader :packed_methods
    attr_reader :tracks
    attr_reader :timeline
    attr_reader :timeline_chunk
    attr_reader :timeline_updates
    attr_reader :known_threads
  end
  
  def Benelux.reset
    @tracks = SelectableHash.new
    @timeline = Timeline.new
    @timeline_chunk = Timeline.new  # See: update_global_timeline
    @timeline_updates = 0
    @known_threads = []
    @processed_dead_threads = []
  end
  reset
  
  @@mutex = Mutex.new
  @@debug = false
  @@logger = STDERR
  
  def Benelux.thread_timeline
    Thread.current.timeline
  end
  
  def Benelux.track(name)
    raise UnknownTrack unless track? name
    @tracks[name]
  end
  
  def Benelux.track?(name)
    @tracks.has_key? name
  end
  
  # If +name+ is specified, this will associate the current
  # thread with that Track +name+ (the Track will be created
  # if necessary).
  #
  # If +track+ is nil, it returns the Track object for the
  # Track associated to the current thread. 
  #
  def Benelux.current_track(name=nil,timeline=nil)
    if name.nil?
      name = Thread.current.track_name
    else
      Thread.current.track_name = name
      @@mutex.synchronize do
        @tracks[name] ||= Track.new(name, timeline || Thread.current.timeline || Benelux::Timeline.new)
        @tracks[name].add_thread Thread.current
        @known_threads << Thread.current
      end
    end
    Benelux.track(name)
  end
  Benelux.current_track :main
  
  def Benelux.merge_tracks
    tl = Benelux::Timeline.new
    tracks.each_pair do |trackid,track|
      tl.merge! track.timeline
    end
    tl
  end
  
  # Only updates data from threads that 
  # are dead and rotated timelines.
  def Benelux.update_global_timeline
    @@mutex.synchronize do
      dthreads = Benelux.known_threads.select { |t| 
        !t.timeline.nil? && (t.nil? || !t.status) &&
        !@processed_dead_threads.member?(t)
      }
      # Threads that have rotated timelines
      rthreads = Benelux.known_threads.select { |t|
        !t.rotated_timelines.empty?
      }
      dtimelines = dthreads.collect { |t| t.timeline }
      # Also get all rotated timelines. 
      rthreads.each { |t| 
        # We loop carefully through the rotated timelines
        # incase something was added while we're working. 
        while !t.rotated_timelines.empty?
          dtimelines.push t.rotated_timelines.shift 
        end
      }
      Benelux.ld [:update_global_timeline, dthreads.size, rthreads.size, dtimelines.size].inspect
      # Keep track of this update separately
      @timeline_chunk = Benelux::Timeline.new
      @timeline_chunk.merge! *dtimelines
      @processed_dead_threads.push *dthreads
      tl = Benelux.timeline.merge! Benelux.timeline_chunk
      @timeline_updates += 1
      tl
    end
  end
  
  def Benelux.inspect
    str = ["Benelux"]
    str << "tracks:" << Benelux.tracks.inspect
    str.join $/
  end
  
  def Benelux.supported?(klass)
    !NOTSUPPORTED.member?(klass)
  end

  
  def Benelux.known_thread?(t=Thread.current)
    Benelux.known_threads.member? t
  end
  
  def Benelux.packed_method(klass, meth)
    return nil unless defined?(Benelux.packed_methods[klass][meth])
    Benelux.packed_methods[klass][meth]
  end
  
  def Benelux.packed_method? klass, meth
    !Benelux.packed_method(klass, meth).nil?
  end
  
  def Benelux.add_timer klass, meth, aliaz=nil, &blk
    raise NotSupported, klass unless Benelux.supported? klass
    raise AlreadyTimed, klass if Benelux.packed_method? klass, meth
    Benelux::MethodTimer.new klass, meth, aliaz, &blk
  end
  
  def Benelux.add_counter klass, meth, aliaz=nil, &blk
    raise NotSupported, klass unless Benelux.supported? klass
    Benelux::MethodCounter.new klass, meth, aliaz, &blk
  end
  
  def Benelux.ld(*msg)
    @@logger.puts "D:  " << msg.join("#{$/}D:  ") if debug?
  end

  
  def Benelux.enable_debug; @@debug = true; end
  def Benelux.disable_debug; @@debug = false; end
  def Benelux.debug?; @@debug; end
  
  # Similar to Benchmark::Tms with the addition of
  # standard deviation, mean, and total, for each of 
  # the data times. 
  #
  #     tms = Benelux::Tms.new
  #     tms.real.sd       # standard deviation
  #     tms.utime.mean    # mean value
  #     tms.total.n       # number of data points
  # 
  # See Benelux::Stats::Calculator
  #
  class Tms < Struct.new :label, :real, :cstime, :cutime, :stime, :utime, :total
    # TODO: integrate w/ http://github.com/copiousfreetime/hitimes
    attr_reader :samples
    # +tms+ is a Benchmark::Tms object
    def initialize tms=nil
      @samples = 0
      members.each_with_index { |n, index| 
        next if n.to_s == 'label'
        self.send("#{n}=", Stats::Calculator.new)
      }
      sample tms unless tms.nil?
    end
    def sample(tms)
      @samples += 1
      self.label ||= tms.label
      members.each_with_index { |n, index| 
        next if n.to_s == 'label'
        self.send(n).sample tms.send(n) || 0
      }
    end
    def to_f
      total.mean.to_f
    end
    def to_i
      total.mean.to_i
    end
    def to_s
      total.mean.to_s
    end
    def inspect
      fields = members.collect { |f| 
        next unless Stats::Calculator === self.send(f)
        '%s=%.2f@%.2f' % [f, self.send(f).mean, self.send(f).sd] 
      }.compact
      args = [self.class.to_s, self.hexoid, samples, fields.join(' ')]
      '#<%s:%s samples=%d %s>' % args
    end
  end
    
  # Run a benchmark the healthy way: with a warmup run, with
  # multiple repetitions, and standard deviation. 
  # 
  # * +n+ Number of times to execute +blk+ (one data sample)
  # * +reps+ Number of data samples to collect
  # * +blk+ a Ruby block to benchmark
  #
  # Returns a Benelux::Tms object
  def Benelux.bm(n=1, reps=5, &blk) 
    require 'benchmark'
    n.times &blk
    tms = Benelux::Tms.new
    reps.times do |rep|
      tms.sample Benchmark.measure() {n.times &blk}
    end
    tms
  end
end




__END__
0.5.0:
ruby -rprofile bin/stella generate -p examples/essentials/plan.rb -c 200 -d 2m localhost:3114
Summary: 
  max clients: 200
  repetitions: 9
    test time:     117.97s
    post time:     156.50s

  %   cumulative   self              self     total
 time   seconds   seconds    calls  ms/call  ms/call  name
 32.38    71.88     71.88      200   359.40   359.40  Thread#join
  9.63    93.25     21.37   166149     0.13     0.20  Selectable::Tags#==
  8.79   112.77     19.52   166149     0.12     0.69  Selectable::Tags#>=
  8.42   131.47     18.70   170598     0.11     0.31  Kernel.send
  4.38   141.19      9.72   166149     0.06     0.39  Selectable::Tags#<=>
  4.31   150.75      9.56    50641     0.19     0.25  Benelux::Stats::Calculator#merge!
  3.74   159.06      8.31   296362     0.03     0.03  Hash#values
  3.03   165.78      6.72   556828     0.01     0.01  Array#size
  2.61   171.57      5.79   166150     0.03     0.05  Array#&
  2.25   176.57      5.00    36169     0.14     0.28  Selectable::Tags#compare_Array
  1.56   180.04      3.47   332505     0.01     0.01  Fixnum#>=
  1.53   183.44      3.40     4224     0.80    26.52  Array#each
  1.32   186.37      2.93   166476     0.02     0.02  Kernel.is_a?
  0.96   188.50      2.13   172011     0.01     0.01  Kernel.class
  0.84   190.36      1.86    50641     0.04     0.05  Selectable::Object.add_tags_quick
  0.83   192.21      1.85    14466     0.13     0.17  Selectable::Tags#compare_Hash
  0.80   193.98      1.77   170551     0.01     0.01  Module#to_s
  0.79   195.73      1.75   152534     0.01     0.01  Float#+
  0.71   197.31      1.58   166192     0.01     0.01  String#intern
  0.64   198.74      1.43    54292     0.03     0.03  Numeric#eql?
  0.63   200.14      1.40    83392     0.02     0.02  String#eql?
  0.53   201.31      1.17   130778     0.01     0.01  Fixnum#==
  0.35   202.09      0.78     7310     0.11     0.15  Enumerable.member?
  0.32   202.81      0.72    35940     0.02     0.02  Hash#==
  0.30   203.48      0.67      201     3.33     6.37  Thread#new
  0.29   204.12      0.64       11    58.18    70.00  Array#collect
  0.27   204.73      0.61    35940     0.02     0.02  Hash#size
  0.27   205.34      0.61      201     3.03     3.03  Thread#initialize
  0.21   205.80      0.46    13901     0.03     0.03  Fixnum#>
  0.21   206.26      0.46      202     2.28     7.08  Kernel.require
  0.20   206.70      0.44    50681     0.01     0.01  Hash#merge!
  0.16   207.05      0.35     2666     0.13     0.13  Array#push
  
0.4.2 and Earlier:
 %   cumulative   self              self     total
time   seconds   seconds    calls  ms/call  ms/call  name
33.04    40.39     40.39   832483     0.05     0.10  Selectable::Tags#==
20.65    65.64     25.25   824759     0.03     0.04  Hash#==
15.38    84.44     18.80     8173     2.30    12.16  Array#select
 6.94    92.93      8.49      101    84.06    84.06  Thread#join
 6.42   100.78      7.85   927328     0.01     0.01  String#==
 5.42   107.40      6.62   832912     0.01     0.01  Kernel.is_a?
 2.01   109.86      2.46    23840     0.10     5.13  Array#each
 0.85   110.90      1.04     9577     0.11     0.46  Selectable::Tags#>=
 0.83   111.92      1.02    13295     0.08     0.87  Kernel.send
 0.67   112.74      0.82     6348     0.13     0.18  Benelux::Stats::Calculator#update
 0.46   113.30      0.56      238     2.35    10.50  Kernel.require
 0.41   113.80      0.50    10620     0.05     0.22  Object#metaclass
 0.36   114.24      0.44    10776     0.04     0.15  Object#metaclass?
 0.35   114.67      0.43     9900     0.04     0.08  Gibbler::Digest#==
 0.35   115.10      0.43     6348     0.07     0.26  Benelux::Stats::Calculator#sample

