
class Stella::CLI < Drydock::Command
  attr_accessor :exit_code
  
  def init
  end
  
  require 'pp'
  def run
    raise Stella::Error, "No URIs" if @argv.empty?
    mode = case @alias
    when "verify"
      :functional
    when "generate"
      :load
    when "preview"
      :preview
    end
    @hosts ||= @argv.collect { |uri|
      uri = 'http://' << uri unless uri.match /^https?:\/\//i
      URI.parse uri
    }
    
    # TODO: replace with Bone integration
    #(@global.var || []).each do |var|
    #  n, v = *var.split('=')
    #  raise "Bad variable format: #{var}" if n.nil? || !n.match(/[a-z]+/i)
    #  Stella::Testplan.global(n.to_sym, v)
    #end
    if @option.testplan
      @testplan = Stella::Testplan.load_file @option.testplan
    else
      @testplan = Stella::Testplan.new
    end
    @testplan.check!  # raise errors, update usecase ratios
    @testplan.freeze  # cascades through usecases and requests
    Stella.li " #{@option.testplan || @testplan.desc} (#{@testplan.gibbler})"
    
    @testrun = Stella::Testrun.new @testplan, @hosts, mode
    @testrun.desc = @option.msg
    opts = [:nowait]  # common options
    case @testrun.mode
    when :functional
    when :load
      opts.push :clients, :duration, :repetitions, :arrival
    else
      raise Stella::Error, "Unknown mode #{mode}"
    end
    opts.each do |opt|
      next if @option.send(opt).nil?
      @testrun.send("#{opt}=", @option.send(opt)) 
    end
    
    
    pp @testrun.gibbler
    
    #@exit_code = (ret ? 0 : 1)
  end
  
  private
  def connect_service
    if @global.remote
      #s = Stella::Service.new 
      #Stella::Engine.service = s
    end
  end

  public 
  # I just don't want to see these
  def example
    base_path = File.expand_path(File.join(STELLA_LIB_HOME, '..'))
    thin_path = File.join(base_path, 'support', 'sample_webapp', 'config.ru')
    webrick_path = File.join(base_path, 'support', 'sample_webapp', 'app.rb')
    tp_path = File.join(base_path, 'examples', 'essentials', 'plan.rb')
    puts "1. Start the web app:".bright
    puts %Q{
    $ thin -p 3114 -R #{thin_path} start
      OR  
    $ ruby #{webrick_path}
    }
    puts "2. Check the web app in your browser".bright
    puts %Q{
    http://127.0.0.1:3114/
    }
    puts "3. Verify the testplan is correct (functional test):".bright
    puts %Q{
    $ stella verify -p #{tp_path} 127.0.0.1:3114
    }
    puts "4. Generate requests (load test):".bright
    puts %Q{
    $ stella generate -p #{tp_path} 127.0.0.1:3114
    }
  end
    
end


module Stella
  class Testplan
    def print_pretty(long=false)
      str = []
      dig = long ? self.digest_cache : self.digest_cache.shorter
      str << " %-66s  ".att(:reverse) % ["#{self.description}  (#{dig})"]
      @usecases.each_with_index do |uc,i| 
        dig = long ? uc.digest_cache : uc.digest_cache.shorter
        desc = uc.description || "Usecase ##{i+1}"
        desc += "  (#{dig}) "
        str << (' ' << " %-61s %s%% ".att(:reverse).bright) % [desc, uc.ratio_pretty]
        unless uc.http_auth.nil?
          str << '    Auth: %s (%s/%s)' % uc.http_auth.values
        end
        requests = uc.requests.each do |r| 
          dig = long ? r.digest_cache : r.digest_cache.shorter
          str << "    %-62s".bright % ["#{r.description}  (#{dig})"]
          str << "      %s" % [r]
          if Stella.stdout.lev > 1
            [:wait].each { |i| str << "      %s: %s" % [i, r.send(i)] }
            str << '       %s: %s' % ['params', r.params.inspect] 
            r.response_handler.each do |status,proc|
              str << "      response: %s%s" % [status, proc.source.split($/).join("#{$/}    ")]
            end
          end
        end
      end
      str.join($/)
    end
  end
end