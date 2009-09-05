
STELLA_LIB_HOME = File.expand_path File.dirname(__FILE__)

module Stella
  autoload :Error, STELLA_LIB_HOME + "/stella/exceptions"
  
  module VERSION #:nodoc:
    unless defined?(MAJOR)
      MAJOR = 0.freeze
      MINOR = 7.freeze
      TINY  = 0.freeze
      PATCH = '001'.freeze
    end
    def self.to_s; [MAJOR, MINOR, TINY].join('.'); end
    def self.to_f; self.to_s.to_f; end
    def self.patch; PATCH; end
  end
  
end

