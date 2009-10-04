

class Stella::CLI < Drydock::Command
  attr_accessor :exit_code
  
  def init
    @conf = Stella::Config.refresh
    @exit_code = 0
  end
  
  def verify_valid?
    create_testplan
  end
  
  def verify
    opts = {}
    opts[:hosts] = @hosts
    opts[:nowait] = true if @option.nowait
    ret = Stella::Engine::Functional.run @testplan, opts
    @exit_code = (ret ? 0 : 1)
  end
  
  def load_valid?
    create_testplan
  end
  
  def load
    opts = {}
    opts[:hosts] = @hosts
    [:nowait, :clients, :repetitions, :delay, :time].each do |opt|
      opts[opt] = @option.send(opt) unless @option.send(opt).nil?
    end
    ret = Stella::Engine::Load.run @testplan, opts
    @exit_code = (ret ? 0 : 1)
  end
  
  def example
    base_path = File.expand_path(File.join(Stella::LIB_HOME, '..'))
    thin_path = File.join(base_path, 'examples', 'example_webapp.ru')
    webrick_path = File.join(base_path, 'examples', 'example_webapp.rb')
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
    puts "3. Run a functional test:".bright
    puts %Q{
    $ stella verify -p #{tp_path} 127.0.0.1:3114
    }
    puts "4. Run a load test:".bright
    puts %Q{
    $ stella load -p #{tp_path} 127.0.0.1:3114
    }
  end
  
  def preview
    create_testplan
    Stella.li @testplan.pretty(Stella.loglev > 1)
  end
  
  private
  def create_testplan
    unless @option.testplan.nil? || File.exists?(@option.testplan)
      raise Stella::InvalidOption, "Bad path: #{@option.testplan}" 
    end
    @hosts = @argv.collect { |uri|; 
      uri = 'http://' << uri unless uri.match /^http:\/\//i
      URI.parse uri; 
    }
    if @option.testplan
      @testplan = Stella::Testplan.load_file @option.testplan
    else
      opts = {}
      opts[:delay] = @option.delay if @option.delay
      @testplan = Stella::Testplan.new(@argv, opts)
    end
    @testplan.check!  # raise errors, update usecase ratios
    Stella.li3 " File: #{@option.testplan} (#{@testplan.digest})", $/
    true
  end
  
  
  
end
