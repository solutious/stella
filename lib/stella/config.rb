

class Stella::Config < Storable
  include Gibbler::Complex
  
  unless defined?(DIR_NAME)
    DIR_NAME = Stella.sysinfo.os == :windows ? 'Stella' : '.stella'
    PATH = {
      :user => File.join(Stella.sysinfo.home, DIR_NAME, 'config'),
      :project => File.join(Dir.pwd, DIR_NAME, 'config')
    }
    PATH_ORDER = [:user, :project]
  end
  
  field :source
  field :apikey
  field :secret
  
  def source?(v)
    return false if @source.nil?
    @source
  end
  
  def self.each_path(&blk)
    Stella::Config::PATH_ORDER.each do |which|
      path = Stella::Config::PATH[which]
      blk.call(path)
    end
  end
  
  def self.refresh
    conf = {}
    Stella::Config.each_path do |path| 
      tmp = YAML.load_file path
      conf.merge! tmp
    end
    from_hash conf
  end
  
  def self.init
    
    Stella::Config::PATH.each_pair do |which,path|
      dir = File.dirname path
      Dir.mkdir(dir, 0700) unless File.exists? dir
      
      unless File.exists? path
        conf = default_config which
        Stella.li "Creating #{path}"
        Stella::Utils.write_to_file(path, conf, 'w', 0600)
      end
    end
    
  end
  
  private 
  
  def self.default_config(which)
    case which
    when :user
      conf = <<CONF
apikey: ''
secret: ''
source:
  remote: 
    host: stella.solutious.com
    port: 443
CONF
    when :project
      conf = <<CONF
target: dev.solutious.com
defaults:
  environment: dev
  testplan: basic
CONF
    end
  end

    
end
