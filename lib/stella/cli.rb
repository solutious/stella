

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
    opts[:benchmark] = true if @option.benchmark
    ret = Stella::Engine::Functional.run @testplan, opts
    @exit_code = (ret ? 0 : 1)
  end
  
  def load_valid?
    create_testplan
  end
  
  def load
    opts = {}
    opts[:hosts] = @hosts
    [:benchmark, :users, :repetitions, :delay, :time].each do |opt|
      opts[opt] = @option.send(opt) unless @option.send(opt).nil?
    end
    ret = Stella::Engine::Load.run @testplan, opts
    @exit_code = (ret ? 0 : 1)
  end

  private
  def create_testplan
    unless File.exists?(@option.testplan)
      raise Stella::InvalidOption, "Bad path: #{v}" 
    end
    @hosts = @argv.collect { |uri|; URI.parse uri; }
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
