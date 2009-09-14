

class Stella::CLI < Drydock::Command
  
  def init
    @conf = Stella::Config.refresh
  end
  
  def verify_valid?
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
    true
  end
  
  def verify
    opts = {
      :hosts => @hosts,
      :benchmark => @option.benchmark || false
    }
    Stella::Engine::Functional.run @testplan, opts
  end
  
  
  def load
    
  end
  
end
