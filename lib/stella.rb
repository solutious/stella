STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__) unless defined?(STELLA_LIB_HOME)

%w{attic gibbler benelux}.each do |dir|
  $:.unshift File.join(STELLA_LIB_HOME, '..', '..', dir, 'lib')
end

require 'dependencies'
autoload :YAML, 'yaml'
autoload :URI, 'uri'
autoload :Gibbler, 'gibbler'

require 'stella/common'

module Stella
  extend self
    
  @globals = {}
  @sysinfo = nil
  @debug   = false
  @abort   = false
  @quiet   = false
  @stdout  = Stella::SyncLogger.new STDOUT
    
  class << self
    attr_reader :stdout
  end
  
  def li(*args) @stdout.puts 1, *args; end
  def le(*msg); li "  " << msg.join("#{$/}  ").color(:red); end
  def ld(*msg)
    return unless Stella.debug?
    prefix = "D(#{Thread.current.object_id}):  "
    li("#{prefix}#{msg.join("#{$/}#{prefix}")}".colour(:yellow))
  end
  
  def sysinfo
    @sysinfo = SysInfo.new.freeze if @sysinfo.nil?
    @sysinfo 
  end
  
  def debug?()        @debug == true  end
  def enable_debug()  @debug =  true  end
  def disable_debug() @debug =  false end
  
  def abort?()        @abort == true  end
  def abort!()        @abort =  true  end
  
  def quiet?()        @quiet == true  end
  def enable_quiet()  @quiet = true   end
  def disable_quiet() @quiet = false  end
  
  def add_global(n,v)
    Stella.ld "SETGLOBAL: #{n}=#{v}"
    @globals[n.strip] = v.strip
  end
  
  def rescue(&blk)
    blk.call
  rescue => ex
    Stella.le "ERROR: #{ex.message}"
    Stella.ld ex.backtrace
  end
  
  #def get(uri, query={})
  #  require 'stella/client'
  #  http_client = HTTPClient.new :agent_name => "Opera/9.51 (Windows NT 5.1; U; en)"
  #  http_client.get(uri, query).body.content
  #rescue => ex
  #  STDERR.puts ex.message
  #  STDERR.puts ex.backtrace if Stella.debug?
  #  nil
  #end
  
  autoload :Testplan, 'stella/testplan'
  autoload :Testrun, 'stella/testrun'
  
end


=begin
module Stella
  module Version
    unless defined?(MAJOR)
      v = YAML.load_file(STELLA_LIB_HOME, 'VERSION.yml')
      MAJOR, MINOR = v[:MAJOR], v[:MINOR]
      PATCH, BUILD = v[:PATCH], v[:BUILD]
    end
    def self.to_s; [MAJOR, MINOR, TINY].join('.'); end
    def self.to_f; self.to_s.to_f; end
    def self.patch; PATCH; end
  end
end
=end
