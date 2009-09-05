

class Stella::CLI < Drydock::Command
  
  def run
    p Stella::Config.from_file('./.stella/config')
  end
  
  
  def init
    Stella::Config.init
  end
  
end
