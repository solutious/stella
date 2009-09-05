

class Stella::Config < Storable
  
  unless defined?(DIR)
    DIR_NAME = Stella.sysinfo.os == :windows ? 'Stella' : '.stella'
    DIR_PATH = File.join(Stella.sysinfo.home, DIR_NAME)
    PATH = File.join(DIR_PATH, 'config')
  end
  
  field :origin
  
  def self.init
    
    unless File.exists?(Stella::Config::DIR_PATH)
      Stella.li "Creating #{Stella::Config::DIR_PATH}"
      Dir.mkdir(Stella::Config::DIR_PATH, 0700)
    end
    
    unless File.exists?(Stella::Config::PATH)
      Stella.li "Creating #{Stella::Config::PATH}"
      conf = Stella::Utils.noindent %Q`
      apikey: ''
      secret: ''
      source:
        remote: 
          host: stella.solutious.com
          port: 443
      `
      Stella::Utils.write_to_file(Stella::Config::PATH, conf, 'w', 0600)
    end
    
  end
  
end
