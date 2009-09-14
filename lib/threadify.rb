module Threadify
  VERSION = '0.0.3'
  def Threadify.version() Threadify::VERSION end

  require 'thread'

  @threads = 8
  @abort_on_exception = true

  class << self
    attr_accessor :threads
    attr_accessor :abort_on_exception
  end

  class Error < ::StandardError; end
end

module Enumerable
  def threadify opts = {}, &block
  # setup
  #
    opts = {:threads => opts} if Numeric === opts
    threads = Integer(opts[:threads] || opts['threads'] || Threadify.threads)
    done = Object.new.freeze
    nothing = done
    #jobs = Array.new(threads).map{ Queue.new }
    jobs = Array.new(threads).map{ [] }
    top = Thread.current

  # produce jobs
  #
    #producer = Thread.new do
      #this = Thread.current
      #this.abort_on_exception = Threadify.abort_on_exception

      each_with_index{|args, i| jobs[i % threads].push([args, i])}
      threads.times{|i| jobs[i].push(done)}
    #end

  # setup consumer list
  #
    consumers = Array.new threads 

  # setup support for short-circuit bailout via 'throw :threadify'
  #
    thrownv = Hash.new
    thrownq = Queue.new

    caught = false

    catcher = Thread.new do
      loop do
        thrown = thrownq.pop
        break if thrown == done
        i, thrown = thrown
        thrownv[i] = thrown
        caught = true
      end
    end

  # fire off the consumers
  #
    threads.times do |i|
      consumers[i] = Thread.new(jobs[i]) do |jobsi|
        this = Thread.current
        this.abort_on_exception = Threadify.abort_on_exception
    
        job = nil

        thrown =
          catch(:threadify) do
            loop{
              break if caught
              #job = jobsi.pop
              job = jobsi.shift
              break if job == done
              args = job.first
              jobsi << (job << block.call(*args))
            }
            nothing
          end


        unless nothing == thrown
          args, i = job
          thrownq.push [i, thrown]
        end
      end
    end

  # wait for consumers to finish
  #
    consumers.map{|t| t.join}

  # nuke the catcher
  #
    thrownq.push done
    catcher.join

  # iff something(s) was thrown return the one which would have been thrown
  # earliest in non-parallel execution
  #
    unless thrownv.empty?
      key = thrownv.keys.sort.first
      return thrownv[key]
    end

  # collect the results and return them
  #
=begin
    jobs.push done
    ret = []
    while((job = jobs.pop) != done)
      elem, i, value = job
      ret[i] = value
    end
    ret
  end
=end

    ret = []
    jobs.each do |results|
      results.each do |result|
        break if result == done
        elem, i, value = result
        ret[i] = value
      end
    end
    ret
  end

end

class Thread
  def Thread.ify enumerable, *args, &block
    enumerable.send :threadify, *args, &block
  end
end

class Object
  def threadify! *values
    throw :threadify, *values
  end
end


if __FILE__ == $0
  require 'open-uri'
  require 'yaml'

  uris = %w( http://google.com http://yahoo.com http://rubyforge.org/ http://ruby-lang.org)

  Thread.ify uris, :threads => 6 do |uri|
    body = open(uri){|pipe| pipe.read}
    y uri => body.size
  end
end


__END__

sample output

--- 
http://yahoo.com: 9562
--- 
http://google.com: 6290
--- 
http://rubyforge.org/: 22352
--- 
http://ruby-lang.org: 9984
