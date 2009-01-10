
      
module Stella::Command
  class Base
    
    
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
    


  end
end