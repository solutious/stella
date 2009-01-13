
module Stella 
  class CLI
    class SystemInfo < Stella::CLI::Base
      
      
      def run
        puts Stella::SYSINFO
      end
      
    end
    
    @@commands['sysinfo'] = Stella::CLI::SystemInfo
  end
end

