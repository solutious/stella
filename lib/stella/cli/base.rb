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
        # NEW WARNING: This puts the process into a new thread which somehow 
        # prevents Pcap from reporting on UDP/DNS packets (TCP/HTTP is unaffected).
        # I left this here as an example of how not to it. Incidentally, 
        # "rescue Interrupt" seems to be working fine now. 
        #@killer = Thread.new do
        #  puts "#{$/}Exiting...#{$/}"
        #  Thread.stop
        #  Thread.main.join(1)
        #  exit 0
        #end
        #
        # Note that this is just a default. Any class that implements another
        # Signal.trap will override this.
        #Signal.trap('INT') do
        #  @killer.call
        #  exit 0
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

