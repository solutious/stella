
class Stella::CLI < Drydock::Command
  attr_accessor :exit_code
  @template_path = File.join(STELLA_LIB_HOME, 'stella', 'cli')
  class << self
    attr_reader :template_path
  end
  
  def init
  end
  
  require 'pp'

  def run
    raise Stella::Error, "No URIs" if @argv.empty?
    
    if @option.testplan
      @testplan = Stella::Testplan.load_file @option.testplan
      @testplan.check!  # raise errors, update usecase ratios
      @testplan.freeze  # cascades through usecases and events
    end
        
    run_opts = [:nowait]  # common options
    case @alias
    when "verify"
      @mode = :functional
    when "generate"
      run_opts.push :clients, :duration, :repetitions, :arrival
      @mode = :load
    when "preview"
      @mode = :preview
      raise Stella::Error, "No testplan provided" if @testplan.nil?
      erb :preview
      exit(0)
    else
      raise Stella::Error, "Unknown mode: #{@alias}"
    end
    
    @testrun = Stella::Testrun.new @hosts, @mode, @testplan
    @testrun.desc = @option.msg
    
    # Convert CLI options to Testplan attributes
    run_opts.each do |opt|
      next if @option.send(opt).nil?
      @testrun.send("#{opt}=", @option.send(opt)) 
    end
    
    pp @testrun.gibbler
    
    #@exit_code = (ret ? 0 : 1)
  end
  
  # I just don't want to see these
  def example
    @base_path = File.expand_path(File.join(STELLA_LIB_HOME, '..'))
    @thin_path = File.join(@base_path, 'support', 'sample_webapp', 'config.ru')
    @webrick_path = File.join(@base_path, 'support', 'sample_webapp', 'app.rb')
    @tp_path = File.join(@base_path, 'examples', 'essentials', 'plan.rb')
    erb :example
  end
  
  
  private
  def connect_service
    if @global.remote
      #s = Stella::Service.new 
      #Stella::Engine.service = s
    end
  end
  
  def erb(name)
    templ = File.read "#{self.class.template_path}/#{name}.erb"
    t = ERB.new templ
    puts t.result(binding)
  end
  

  
end
