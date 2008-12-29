

module Stella::Adapter
  class CommandNotReady < RuntimeError
    def initialize(name="")
      super(Stella::TEXT.msg(:error_adapter_command_not_ready, name))
    end
  end
  
  class Base
    
    
    attr_accessor :arguments, :load_factor, :working_directory, :stats
    
    def initialize(options={}, arguments=[])
      self.arguments = arguments
      self.options = options
    end
    
    def load_factor=(load_factor)
      @load_factor = load_factor
    end
    def stdout_path
      File.join(@working_directory, 'STDOUT.txt')
    end
    
    def stderr_path
      File.join(@working_directory, 'STDERR.txt')
    end
    
    def summary_path(ext='yaml')
      File.join(@working_directory, "SUMMARY.#{ext}")
    end
    
    # process_options
    #
    # This method must be overridden by the implementing class. This is intended
    # for processing the command-specific command-line arguments
    def process_options
      raise Stella::TEXT.msg(:error_class_must_override, 'process_options')
    end
    
    def options=(options={})
      options = options.marshal_dump if options.is_a? OpenStruct
      unless options.nil? || options.empty?
        options.each_pair do |name,value|
          next if @private_variables.member?(name)
          Stella::LOGGER.info(:error_class_unknown_argument, name) && next unless self.respond_to?("#{name.to_s}=")
          instance_variable_set("@#{name.to_s}", value)
        end
      end
    end
    
    def arguments=(arguments=[])
      @arguments = arguments unless arguments.nil? 
    end
    
    def available?
      (version.to_f > 0)
    end
    
    def name
      @name
    end
    
    def rate
      1
    end
    def vuser_rate
      "#{vusers}/#{rate}"
    end
    
    def command
      raise Stella::TEXT.msg(:error_class_must_override, 'command')
    end
    
    def add_header
      raise Stella::TEXT.msg(:error_class_must_override, 'add_header')
    end
    
    def user_agent=
      raise Stella::TEXT.msg(:error_class_must_override, 'user_agent=')
    end
    
    private
    
    
  end
end
  