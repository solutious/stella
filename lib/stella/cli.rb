

class Stella::CLI < Drydock::Command
  
  def init
    @conf = Stella::Config.refresh
  end
  
  def verify_valid?
    true
  end
  
  def verify
    Stella.run( :testplan => @option.testplan )
  end
  
  
end
