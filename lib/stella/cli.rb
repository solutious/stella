
class Stella::CLI < Drydock::Command
  attr_accessor :exit_code
  
  def init
  end
  
  require 'pp'
  def verify
    get_hosts
    create_testplan
    create_testrun :functional
    pp @testrun
    
    #@exit_code = (ret ? 0 : 1)
  end
  
  def generate_valid?
    
  end
  
  def generate
    
    #@exit_code = (ret ? 0 : 1)
  end
  
  def preview
    
  end
  
  private
  def connect_service
    if @global.remote
      #s = Stella::Service.new 
      #Stella::Engine.service = s
    end
  end
  
  def get_hosts
    raise Stella::Error, "No URIs" if @argv.empty?
    @hosts ||= @argv.collect { |uri|
      uri = 'http://' << uri unless uri.match /^https?:\/\//i
      URI.parse uri
    }
  end
  
  def create_testplan
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
    true
  end
  
  def create_testrun(mode)
    @testrun = Stella::Testrun.new @testplan, @hosts
    @testrun.desc = @option.msg
    opts = [:mode, :nowait]
    case @testrun.mode
    when :functional
    when :load
      opts.push :client, :duration, :repetitions, :arrival
    else
      raise Stella::Error, "Unknown mode #{mode}"
    end
    opts.each do |opt|
      next if @option.send(opt).nil?
      @testrun.send("#{opt}=", @option.send(opt)) 
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
