

class Stella::CLI < Drydock::Command
  
  def init
    @conf = Stella::Config.refresh
  end
  
  def verify_valid?
    true
  end
  
  def verify
    if @option.testplan
      testplan = Stella::Testplan.load_file @option.testplan
    else
      uri = URI.parse @args.first
      testplan = Stella::Testplan.new
      usecase = Stella::Testplan::Usecase.new
      usecase.add_request :get, uri.path
      testplan.add_usecase usecase
    end
    
    Stella::Engine::Functional.run testplan
  end
  
  
  def load
    
  end
  
end
