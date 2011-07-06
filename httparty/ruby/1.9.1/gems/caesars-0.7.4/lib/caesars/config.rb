
# A helper for loading a DSL from a config file.
#
# Usage:
#
#      class Staff < Caesars; end;
#      class StaffConfig < Caesars::Config
#        dsl Staff::DSL
#      end
#      @config = StaffConfig.new('/path/2/staff_dsl.rb')
#      p @config.staff    # => <Staff:0x7ea450 ... >
#
class Caesars
  class Config
    attr_accessor :paths
    attr_reader :options
    attr_reader :verbose

    @@glasses = []

    # Used by postprocess to tell refresh to reload all configs.
    class ForceRefresh < RuntimeError
      # The list of config types that need to be refreshed. This is currently
      # for informational-purposes only. It does not affect which files/config
      # types are refreshed. See Caesars::Config::ForcedRefresh
      attr_reader :glasses 
      def initialize(*glasses); @glasses = glasses; end
      def message; "Force refresh of: #{@glasses.join(',')}"; end
    end

    # +args+ is a last of config file paths to load into this instance.
    # If the last argument is a hash, it's assumed to be a list of 
    # options. The available options are:
    #
    # <li>:verbose => true or false</li>
    #
    def initialize(*args)
      # We store the options hash b/c we reapply them when we refresh.
      @options = args.last.kind_of?(Hash) ? args.pop : {}
      @paths = args.empty? ? [] : args
      @options = {}
      @forced_refreshes = 0
      refresh
    end

    def verbose=(enable)
      @verbose = enable == true
      @options[:verbose] = @verbose
    end

    # Reset all config instance variables to nil.
    def caesars_init
      # Remove instance variables used to populate DSL data
      keys.each { |confname| instance_variable_set("@#{confname}", nil) }
      # Re-apply options
      @options.each_pair do |n,v|
        self.send("#{n}=", v) if respond_to?("#{n}=")
      end
      check_paths     # make sure files exist
    end

    # This method is a stub. It gets called by refresh after each 
    # config file has be loaded. You can use it to run file specific
    # processing on the configuration before it's used elsewhere. 
    def postprocess
    end

    # Clear all current configuration (sets all config instance
    # variables to nil) and reload all config files in +@paths+.
    # After each path is loaded, Caesars::Config.postprocess is
    # called. If a ForceRefresh exception is raise, refresh is
    # run again from the start. This is useful in the case 
    # where one DSL can affect the parsing of another. Note that
    # refresh only clears the instance variables, the class vars
    # for each of the DSLs are not affected so all calls to
    # +forced_array+, +forced_hash+, +chill+ and +forced_ignore+
    # are unaffected. 
    #
    # Rudy has an example of forced refreshing in action. See 
    # the files (http://github.com/solutious/rudy):
    #
    # * +lib/rudy/config.rb+
    # * +lib/rudy/config/objects.rb+. 
    # 
    def refresh
      caesars_init    # Delete all current configuration
      @@glasses.each { |glass| extend glass }
  
      begin
        current_path = nil  # used in error messages
        @paths.each do |path|
          current_path = path
          puts "Loading config from #{path}" if @verbose || Caesars.debug?
          dsl = File.read path
          # eval so the DSL code can be executed in this namespace.
          eval dsl, binding, path
        end
    
        # Execute Caesars::Config.postprocesses after all files are loaded. 
        postprocess # Can raise ForceRefresh
    
      rescue Caesars::Config::ForceRefresh => ex
        @forced_refreshes += 1
        if @forced_refreshes > 3
          STDERR.puts "Too many forced refreshes (#{@forced_refreshes})"
          exit 9
        end
        STDERR.puts ex.message if @verbose || Caesars.debug?
        refresh
    
      #rescue Caesars::Error => ex
      #  STDERR.puts ex.message
      #  STDERR.puts ex.backtrace if Caesars.debug?
      rescue ArgumentError, SyntaxError => ex
        newex = Caesars::SyntaxError.new(current_path)
        newex.backtrace = ex.backtrace
        raise newex
      end
    end

    # Checks all values of +@paths+, raises an exception for nil
    # values and file paths that don't exist.
    def check_paths
      @paths.each do |path|
        raise "You provided a nil value" unless path
        raise "Config file #{path} does not exist!" unless File.exists?(path)
      end
    end

    # Do any of the known DSLs have config data?
    def empty?
      keys.each do |obj|
        return false if self.respond_to?(obj.to_sym)
      end
      true
    end

    # Specify a DSL class (+glass+) to include in this config. 
    # 
    #     class CoolDrink < Caesars::Config
    #       dsl CoolDrink::Flavours::DSL
    #     end
    #
    def self.dsl(glass)
      @@glasses << glass
    end

    # Provide a hash-like interface for Config classes.
    # +name+ is the name of a DSL config. 
    #
    #     class CoolDrink < Caesars::Config
    #       dsl CoolDrink::Flavours::DSL
    #     end
    #
    #     cd = CoolDrink.new('/path/2/config')
    #     cd[:flavours]     # => {}
    #
    def [](name)
      self.send(name) if respond_to?(name)
    end

    # Returns the list of known DSL config names. 
    #     class CoolDrink < Caesars::Config
    #       dsl CoolDrink::Flavours::DSL
    #     end
    #
    #     cd = CoolDrink.new('/path/2/config')
    #     cd.keys           # => [:flavours]
    #
    def keys
      @@glasses.collect { |glass| glass.methname }
    end

    # Is +name+ a known configuration type?
    #
    #     class CoolDrink < Caesars::Config
    #       dsl CoolDrink::Flavours::DSL
    #     end
    #
    #     cd = CoolDrink.new('/path/2/config')
    #     cd.has_key?(:taste)        # => false
    #     cd.has_key?(:flavours)     # => true
    #
    def has_key?(name)
      respond_to?(name)
    end
    
  end
end

