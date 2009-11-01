

class Stella::Config < Storable
  include Gibbler::Complex

  field :source
  field :apikey
  field :secret
    
   # Returns true when the current config matches the default config
  def default?; to_hash.gibbler == DEFAULT_CONFIG_HASH; end
  
  def self.each_path(&blk)
    [PROJECT_PATH, USER_PATH].each do |path|
      Stella.ld "Loading #{path}"
      blk.call(path) if File.exists? path
    end
  end
  
  def self.refresh
    conf = {}
    Stella::Config.each_path do |path| 
      tmp = YAML.load_file path
      conf.merge! tmp if tmp
    end
    from_hash conf
  end
  
  def self.init
    raise AlreadyInitialized, PROJECT_PATH if File.exists? PROJECT_PATH
    dir = File.dirname USER_PATH
    Dir.mkdir(dir, 0700) unless File.exists? dir
    unless File.exists? USER_PATH
      Stella.li "Creating #{USER_PATH} (Add your credentials here)"
      Stella::Utils.write_to_file(USER_PATH, DEFAULT_CONFIG, 'w', 0600)
    end
    
    dir = File.dirname PROJECT_PATH
    Dir.mkdir(dir, 0700) unless File.exists? dir
    
    Stella.li "Creating #{PROJECT_PATH}"
    Stella::Utils.write_to_file(PROJECT_PATH, 'target:', 'w', 0600)
  end
  
  def self.blast
    if File.exists? USER_PATH
      Stella.li "Blasting #{USER_PATH}"
      FileUtils.rm_rf File.dirname(USER_PATH)
    end
    if File.exists? PROJECT_PATH
      Stella.li "Blasting #{PROJECT_PATH}"
      FileUtils.rm_rf File.dirname(PROJECT_PATH)
    end
  end
 
  def self.project_dir
    File.join(Dir.pwd, DIR_NAME)
  end
  
  private 
  
  def self.find_project_config
    dir = Dir.pwd.split File::SEPARATOR
    path = nil
    while !dir.empty?
      tmp = File.join(dir.join(File::SEPARATOR), DIR_NAME, 'config')
      Stella.ld " -> looking for #{tmp}"
      path = tmp and break if File.exists? tmp
      dir.pop
    end
    path ||= File.join(Dir.pwd, DIR_NAME, 'config')
    path
  end
  
  
  unless defined?(DIR_NAME)
    DIR_NAME = Stella.sysinfo.os == :windows ? 'Stella' : '.stella'
    USER_PATH = File.join(Stella.sysinfo.home, DIR_NAME, 'config')
    PROJECT_PATH = Stella::Config.find_project_config
    DEFAULT_CONFIG = <<CONF
apikey: ''
secret: ''
remote: stella.solutious.com:443
CONF
    DEFAULT_CONFIG_HASH = YAML.load(DEFAULT_CONFIG).gibbler
  end
    
  class AlreadyInitialized < Stella::Error; end
end

