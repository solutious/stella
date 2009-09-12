

module Stella::Engine
  module Base
    extend self
    def run
      raise "override the run method"
    end
  end
end

Stella::Utils.require_glob(STELLA_LIB_HOME, 'stella', 'engine', '*.rb')