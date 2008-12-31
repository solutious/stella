
      
module Stella::Command
  class Base
    
    BrowserNicks = {
      'ff' => 'firefox',
      'ie' => 'internetexplorer'
    }.freeze unless defined? BrowserNicks

    OperatingSystemNicks = {
      'win' => 'windows',
      'lin' => 'linux',
      'osx' => 'osx',
      'freebsd' => 'bsd',
      'netbsd' => 'bsd',
      'openbsd' => 'bsd'
    }.freeze unless defined? OperatingSystemNicks
    
    # TODO: See EC2::Platform for example to improve/generalize platform
    # discovery. We'll need this for monitoring. 
    IMPLEMENTATIONS = [
      [/darwin/i,  :unix,    :macosx ]
    ]
    ARCHITECTURES = [
      [/(i\d86)/i,  :i386             ]
    ]
    
    # When using Stella::CLI this will contain the string used to call this command
    # i.e. ab, siege, help, etc...
    attr_accessor :shortname
    
    
    def initialize()
      
      #agent = find_agent(*expand_str(v)) 
      #@logger.info(:cli_print_agent, agent) if @options.verbose >= 1

    end
    
    def run_sleeper(duration)
      remainder = duration % 1 
      duration.to_i.times {
        Stella::LOGGER.info_print('.') unless @quiet
        sleep 1
      }
      sleep remainder if remainder > 0
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
    def find_agent(name,second=nil,third=nil)
      name = (BrowserNicks.has_key?(name)) ? BrowserNicks[name] : name
      return name unless @available_agents.has_key?(name) || name == "random"

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
        index = @available_agents.keys[ rand(@available_agents.keys.size) ]
      end

      # Attempt to find a pool of user agents that match the supplied index
      ua_pool = @available_agents[index]

      # In the event we don't find an agent above (which will only happen
      # when the user provided a version), we'll take a random agent for 
      # the same browser and apply the version supplied by the user. We 
      # create the index using just the major version number so if the user
      # supplies a specific verswion number, they will always end up here.
      unless ua_pool
        os = (OperatingSystemNicks.has_key?(third)) ? OperatingSystemNicks[third] : third
        index = (os) ? "#{name}-#{os}" : name
        ua_tmp = @available_agents[index][ rand(@available_agents[index].size) ]
        ua_tmp.version = second if second.to_i > 0
        ua_pool = [ua_tmp]
      end

      ua = ua_pool[ rand(ua_pool.size) ]

      ua.to_s

    end


  end
end