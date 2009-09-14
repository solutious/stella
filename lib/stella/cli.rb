

class Stella::CLI < Drydock::Command
  
  def init
    @conf = Stella::Config.refresh
  end
  
  def verify_valid?
    create_testplan
  end
  
  def verify
    opts = {}
    opts[:hosts] = @hosts
    opts[:benchmark] = true if @option.benchmark
    Stella::Engine::Functional.run @testplan, opts
  end
  
  def load_valid?
    create_testplan
  end
  
  def load
    opts = {}
    opts[:hosts] = @hosts
    [:benchmark, :users].each do |opt|
      opts[opt] = @option.send(opt) unless @option.send(opt).nil?
    end
    Stella::Engine::Load.run @testplan, opts
  end
  
  def preview_valid?
    create_testplan
  end
  
  def preview
    Stella.li2 "file: #{@option.testplan} (#{@testplan.digest})"
    Stella.li @testplan.pretty
  end


  private
  def create_testplan
    @hosts = @argv.collect { |uri|; URI.parse uri; }
    if @option.testplan
      @testplan = Stella::Testplan.load_file @option.testplan
    else
      @testplan = Stella::Testplan.new
      usecase = Stella::Testplan::Usecase.new
      @argv.each do |uri|
        uri = URI.parse uri
        uri.path = '/' if uri.path.empty?
        usecase.add_request :get, uri.path
      end
      @testplan.add_usecase usecase
    end
    Stella.ld "PLANHASH: #{@testplan.digest}"
    @testplan.check!  # raise errors
    true
  end
  
  
  
end
