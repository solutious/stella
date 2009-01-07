


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
      @reason = Stella::TEXT.err(reason) if reason.kind_of? Symbol
    end
    def message
      Stella::TEXT.err(:error_missing_dependency, @dependency, @reason)
    end
  end
  
  class Util
    
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
    def self.process_useragents(ua_strs=[])
      agents_index = {}
      return agents_index if ua_strs.empty?

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
    
    # expand_str
    # 
    # Turns a string like ff-4-freebsd into ["ff","4","freebsd"]
    # We use this for command-line values liek agent and rampup
    def self.expand_str(str)
      str.split(/\s*[,\-]\s*/) # remove extra spaces at the same time. 
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
