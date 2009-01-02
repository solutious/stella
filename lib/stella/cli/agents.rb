


module Stella 
  class CLI
    
    class Agents < Stella::CLI::Base
      
      attr_accessor :full
      attr_accessor :list
      attr_accessor :search
      attr_accessor :help
      
      def initialize(adapter)
        super(adapter)
        @full = false
        @list = false
        @help = false
      end
      
      def run
        process_options
        
        if @help
          process_options(:display)
          return
        end
        
        # The LocalTest command is the keeper of the user agents
        localtest = Stella::LocalTest.new
        
        agents = []
        all_agents = localtest.available_agents
        all_agents.each_pair do |key,value|
          if (@full) 
            value.each do |full_value|
              agent = full_value.join(' ')
              agents << agent if (!@search || agent.to_s.match(/#{search}/i))
            end
          else
            agents << key.to_s if (!@search || key.to_s.match(/#{search}/i))
          end
        end
 
        msg = (@list) ? agents.uniq.sort.join("\n") : Stella::TEXT.msg(:agents_count_message, agents.uniq.size)
        puts msg
      end
      
      def process_options(display=false)

        opts = OptionParser.new
        opts.banner = Stella::TEXT.msg(:option_help_usage)
        opts.on('-h', '--help', Stella::TEXT.msg(:option_help_help)) { @help = true }
        opts.on('-f', '--full', Stella::TEXT.msg(:agents_option_full)) { @full = true }
        opts.on('-l', '--list', Stella::TEXT.msg(:agents_option_list)) { @list = true }
        # TODO: display agents based on shortnames. This is important to maintain continuity with the stella option. 
        #opts.on('-a', '--agent', Stella::TEXT.msg(:agents_option_list)) { @list = true } 
        opts.on('-s', '--search=S', String, Stella::TEXT.msg(:agents_option_search)) { |v| @search = v }
        
        opts.parse!(@arguments)
        
        if display
          Stella::LOGGER.info opts
          return
        end
        
      end
      
    end
    
    @@commands['agents'] = Stella::CLI::Agents
  end
end