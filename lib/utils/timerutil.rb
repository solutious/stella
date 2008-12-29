
require 'benchmark'

class TimerUtil
  
  attr_reader :tstart, :tend, :rstart, :rend
  attr_reader :time
  
  def initialize(label="default")
    @tstart, @rstart = 0,0
    @tend, @rend = 0,0
    @label = label
    @time = Benchmark::Tms.new
  end
  
  def start
    @tstart, @rstart = Benchmark.times, Time.now
  end
  
  def stop
    @tend, @rend = Benchmark.times, Time.now
    
    @time = Benchmark::Tms.new(@tend.utime  - @tstart.utime,
                               @tend.stime  - @tstart.stime,
                               @tend.cutime - @tstart.cutime,
                               @tend.cstime - @tstart.cstime,
                               @rend.to_f - @rstart.to_f,
                               @label)
  end
  
  def utime
    @time.utime
  end
  def stime
    @time.stime
  end
  def cutime
    @time.cutime
  end
  def cstime
    @time.cstime
  end
  def total
    @time.total
  end
  def real
    @time.real
  end
  def format(formatstr=nil)
    @time.format(formatstr)
  end
  def label
    @time.label
  end
  
end 
  
  