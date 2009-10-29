

module Stella
  module VERSION
    unless defined?(MAJOR)
      MAJOR = 0.freeze
      MINOR = 7.freeze
      TINY  = 2.freeze
      PATCH = '001'.freeze
    end
    def self.to_s; [MAJOR, MINOR, TINY].join('.'); end
    def self.to_f; self.to_s.to_f; end
    def self.patch; PATCH; end
  end
end