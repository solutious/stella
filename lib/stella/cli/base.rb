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

