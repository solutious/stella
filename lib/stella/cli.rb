

class Stella::CLI < Drydock::Command
  
  def init
    @conf = Stella::Config.refresh
  end
  
  def verify
    p @conf
  end
  
  
end
