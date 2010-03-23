
class Stella::CLI < Drydock::Command
  attr_accessor :exit_code
  
  def init
    @conf = Stella::Config.refresh
    @exit_code = 0
  end
  
  def config
    puts @conf.to_yaml
  end
  
  def verify_valid?
    create_testplan
  end

  def generate_valid?
    create_testplan
  end
  
  def run(mode)
    opts = { :mode => mode }
    opts[:hosts] = @hosts
    [:nowait, :clients, :repetitions, :duration, :arrival, :granularity].each do |opt|
      opts[opt] = @option.send(opt) unless @option.send(opt).nil?
    end
    [:'notemplates', :'nostats', :'noheader', :'noparam'].each do |opt|
      opts[opt] = @global.send(opt) unless @global.send(opt).nil?
    end
    testrun = Stella::Testrun.new @testplan, opts
    testrun.run
    testrun
  end
  
  def generate
    testrun = run :generate
    @exit_code = (testrun.has_errors? == 0 ? 0 : 1)
  end
  def verify
    testrun = run :verify
    @exit_code = (testrun.has_errors? == 0 ? 0 : 1)
  end
    
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
  
  def preview
    create_testplan
    if @global.format == 'json'
      Stella.stdout.info @testplan.to_json
    else
      Stella.stdout.info @testplan.pretty(Stella.stdout.lev > 1)
    end
  end
  
  private
  
  def create_testplan
    unless @option.testplan.nil? || File.exists?(@option.testplan)
      raise Stella::InvalidOption, "Bad path: #{@option.testplan}" 
    end
    (@global.var || []).each do |var|
      n, v = *var.split('=')
      raise "Bad variable format: #{var}" if n.nil? || !n.match(/[a-z]+/i)
      Stella::Testplan.global(n.to_sym, v)
    end
    if @option.testplan
      @hosts = @argv.collect { |uri|; 
        uri = 'http://' << uri unless uri.match /^https?:\/\//i
        URI.parse uri; 
      }
      @testplan = Stella::Testplan.load_file @option.testplan
    else
      opts = {}
      opts[:wait] = @option.wait if @option.wait
      @testplan = Stella::Testplan.new(@argv)
    end
    @testplan.check!  # raise errors, update usecase ratios
    @testplan.freeze  # cascades through usecases and requests
    true
  end
  
  
  
end
