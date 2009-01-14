


module Stella
  
  class InvalidArgument < RuntimeError
    attr_accessor :name
    def initialize(name)
      @name = name
    end
    def message
      Stella::TEXT.err(:error_invalid_argument, @name)
    end
    
  end
  
  class UnavailableAdapter < RuntimeError
    attr_accessor :name
    def initialize(name)
      @name = name
    end
    def message
      Stella::TEXT.err(:error_unavailable_adapter, @name)
    end
  end
  
  class UnknownValue < RuntimeError
    attr_accessor :value
    def initialize(value)
      @value = value.to_s
    end
    def message
      Stella::TEXT.err(:error_unknown_value, @value)
    end
  end
  
  class UnsupportedLanguage < RuntimeError
  end
  
  class MissingDependency < RuntimeError
    attr_accessor :dependency, :reason
    def initialize(dependency, reason=:error_generic)
      @dependency = dependency
      @reason = (reason.kind_of? Symbol) ? Stella::TEXT.err(reason) : reason
    end
    def message
      Stella::TEXT.err(:error_missing_dependency, @dependency, @reason)
    end
  end
  
  class AdapterError < MissingDependency
    def initialize(adapter, reason=:error_generic)
      @adapter = adapter
      @reason = (reason.kind_of? Symbol) ? Stella::TEXT.err(reason) : reason
    end
    def message
      Stella::TEXT.err(:error_adapter_runtime, @adapter, @reason)
    end
  end
  
  class Util
    
    BrowserNicks = {
      :ff => 'firefox',
      :ie => 'internetexplorer'
    }.freeze unless defined? BrowserNicks

    OperatingSystemNicks = {
      :win => 'windows',
      :lin => 'linux',
      :osx => 'osx',
      :freebsd => 'bsd',
      :netbsd => 'bsd',
      :openbsd => 'bsd'
    }.freeze unless defined? OperatingSystemNicks
    
    # process_useragents
    #
    # We read the useragents.txt file into a hash index which 
    # useful for refering to specific useragents on the command-line
    # and other places. 
    # 
    # Examples:
    #      --agent=ie-5
    #      --agent=ff-2.0.0.2-linux
    #      --agent=chrome-windows
    #      --agent=safari-3.0-osx
    # 
    def self.process_useragents(path=nil)
      raise "Cannot find #{path}" unless File.exists? path
      ua_strs = FileUtil.read_file_to_array(path)
      return {} if ua_strs.empty?
      
      agents_index = {}
      ua_strs.each do |ua_str|
        ua_str.chomp!   # remove trailing line separator

        ua = UserAgent.parse(ua_str)
        
        # Standardize the index values
        # i.e. firefox-3-windows
        name = ua.browser.downcase.tr(' ', '')
        version = ua.version.to_i
        os = ua.platform.downcase.tr(' ', '')

        # Non-windows operating systems have the OS string inside of "os"
        # rather than "platform". We look there for the value and then
        # standardize the values. 
        # i.e. firefox-3-osx
        if os != 'windows'
          os = ua.os.downcase
          os = 'linux' if os.match(/^linux/)
          os = 'osx' if os.match(/mac os x/)
          os = 'bsd' if os.match(/bsd/)
        end

        # Make sure all arrays exist before we populate them
        agents_index[name] ||= []
        agents_index["#{name}-#{version}"] ||= []
        agents_index["#{name}-#{version}-#{os}"] ||= []
        agents_index["#{name}-#{os}"] ||= [] # We use this one for failover

        # Populate each list. 
        agents_index[name] << ua
        agents_index["#{name}-#{version}"] << ua
        agents_index["#{name}-#{version}-#{os}"] << ua
        agents_index["#{name}-#{os}"] << ua

      end

      agents_index
    end
    
    def self.find_agents(agent_list, possible_agents=[])
      return [] if agent_list.nil? || agent_list.empty?
      return [] if possible_agents.nil? || possible_agents.empty?
      
      agents = []
      possible_agents.each do |a|
        agents << Stella::Util.find_agent(agent_list, *a)
      end
      
      agents
    end
    
    # find_agent
    #
    # Takes an input string which can be either a shortname or a complete
    # user agent string. If the string matches the shortname format, it
    # will select an agent string from useragents.txt based on the shortname.
    # Shortname takes the following format: browser-version-os. 
    # Examples: ff-3-linux, ie-5, opera-10-win, chrome-0.2-osx, random
    # If os doesn't match, it will look for the browser and version. If it can't
    # find the version it will look for the browser and apply the version given. 
    # If browser doesn't match a known browser, it assumes the string is a 
    # complete user agent and simply returns that value. 
    def self.find_agent(agent_list, name,second=nil,third=nil)
      return '' if agent_list.nil? || agent_list.empty?
      name = (BrowserNicks.has_key?(name.to_s.to_sym)) ? BrowserNicks[name.to_s.to_sym] : name
      return name unless agent_list.has_key?(name) || name == "random"

      index = name
      if (second && third)                # i.e. opera-9-osx
        os = (OperatingSystemNicks.has_key?(third)) ? OperatingSystemNicks[third] : third
        index = "#{name}-#{second}-#{os}"
      elsif(second && second.to_i > 0)    # i.e. opera-9
        index = "#{name}-#{second}"
      elsif(second)                       # i.e. opera-osx
        os = (OperatingSystemNicks.has_key?(second)) ? OperatingSystemNicks[second] : second
        index = "#{name}-#{os}"
      elsif(name == "random")
        index = agent_list.keys[ rand(agent_list.keys.size) ]
      end

      # Attempt to find a pool of user agents that match the supplied index
      ua_pool = agent_list[index]

      # In the event we don't find an agent above (which will only happen
      # when the user provided a version), we'll take a random agent for 
      # the same browser and apply the version supplied by the user. We 
      # create the index using just the major version number so if the user
      # supplies a specific verswion number, they will always end up here.
      unless ua_pool
        os = (OperatingSystemNicks.has_key?(third)) ? OperatingSystemNicks[third] : third
        index = (os) ? "#{name}-#{os}" : name
        ua_tmp = agent_list[index][ rand(agent_list[index].size) ]
        ua_tmp.version = second if second.to_i > 0
        ua_pool = [ua_tmp]
      end
      
      ua = ua_pool[ rand(ua_pool.size) ]
      
      ua.to_s

    end
    
    # expand_str
    # 
    # Turns a string like ff-4-freebsd into ["ff","4","freebsd"]
    # We use this for command-line values liek agent and rampup.
    # +str+ is a comma or dash separated string.
    # +type+ is a class type to cast to (optional, default: String)
    def self.expand_str(str, type=String)
      # this removes extra spaces along with the comma
      str.split(/\s*[,\-]\s*/).inject([]) do |list,value| list << eval("#{type}('#{value}')") end
    end
    
    
    # capture_output
    #
    # +cmd+ is a shell command to run with Kernel.` It will be appended with 
    # redirects to send STDOUT and STDERR to temp files. If the command already
    # contains redirects they will be removed and replaced. 
    # The tempfiles are sent to yield as arrays of lines (using file_sout.readlines)
    # and deleted before returning. 
    #
    # We use files because popen and open3 are not implemented on Windows. 
    def self.capture_output(cmd)
      return unless cmd
      file_sout = Tempfile.new("stdout" << strand(6)) # We add a strand to be super sure it doesn't exist
      file_serr = Tempfile.new("stderr" << strand(6))
      cmd.gsub!(/1>.+/, '')
      cmd.gsub!(/2>.+/, '')
      cmd = "#{cmd} 1> \"#{file_sout.path}\" 2> \"#{file_serr.path}\""
      begin
        # Windows will have a conniption because the tempfiles are already open.
        # We close them here and then open them to read them. 
        file_sout.close
        file_serr.close
        
        system(cmd)
        
        file_sout.open
        file_serr.open
        sout, serr = file_sout.readlines, file_serr.readlines
        file_sout.close
        file_serr.close
        
        yield(sout, serr)
        
      ensure
        file_sout.delete
        file_serr.delete
      end
    end
    
    # NOTE: Not used yet
    # TODO: Use capture instead of capture_output
    # Stolen from http://github.com/wycats/thor
    def capture(stream)
      begin
        stream = stream.to_s
        eval "$#{stream} = StringIO.new"
        yield
        result = eval("$#{stream}").string
      ensure
        eval("$#{stream} = #{stream.upcase}")
      end

      result
    end
    
    
    # 
    # Generates a string of random alphanumeric characters
    # These are used as IDs throughout the system
    def self.strand( len )
       chars = ("a".."z").to_a + ("0".."9").to_a
       newpass = ""
       1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
       return newpass
    end
    
  end
  
end
