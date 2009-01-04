module Stella
  class CLI
    # Stella::CLI::Base
    #
    # A base case for the command line interface classes. All Stella::CLI 
    # classes should be based on this class. Otherwise great destruction could occur.
    class Base
      attr_reader :adapter
      attr_accessor :stella_options
      attr_accessor :arguments
      attr_accessor :working_directory
      
      def initialize(adapter)
        @adapter_name = adapter
        @options = OpenStruct.new
        
        # There is a bug in Ruby 1.8.6 where a trapped SIGINT will hang. 
        # This workaround is from: http://redmine.ruby-lang.org/issues/show/362 
        # It works in Ruby 1.9 and JRuby as well.  
        #@killer = Thread.new do
        #  Thread.stop
        #  puts "#{$/}Exiting...#{$/}"
        #  Thread.main.join(1)
        #  exit 0
        #end
        #
        ## Note that this is just a default. Any class that implements another
        ## Signal.trap will override this.
        #Signal.trap('INT') do
        #  @killer.run
        #end
      end
    end
  end
end

__END__

TODO: Investigate frylock style definition
include Stella::CLI::Base

before do
  # stuff that would go in initialize
end

command 'sysinfo' do
  puts Stella::SYSINFO.to_yaml(:headers)
end

