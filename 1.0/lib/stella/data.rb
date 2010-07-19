
module Stella::Data
  extend self
    
  module Helpers
    
    def resource(args)   to_templ(:resource, *args)   end
    
    # Can include glob
    #
    # e.g.
    #    random_file('avatar*')
    def random_file(*args)  to_templ(:random_file, *args)    end
    
    def read_file(*args) to_templ(:read_file, *args)    end
    
    def path(*args)   to_templ(:path, *args)     end
    
    def file(*args)   to_templ(:file, *args)    end
    
    def random(*args)
      to_templ(:random, *args)
    end
    
    
    # NOTE: This is global across all users
    def sequential(*args)
      to_templ(:sequential, *args)
    end
    
    # NOTE: This is global across all users
    def rsequential(*args)
      to_templ(:rsequential, *args)
    end
    
    private 

    def args_to_str(*args)
      args.collect! do |el|
        if el.kind_of?(Enumerable) || el.kind_of?(Numeric)
          el.inspect
        elsif el.is_a?(Symbol)
          ":#{el.to_s}"
        else
          "'#{el.to_s}'"
        end 
      end
      args.join(', ')
    end
    
    def to_templ(meth, *args)
      "<%= #{meth}(#{args_to_str(*args)}) %>"
    end
    
  end
      
end

Stella::Utils.require_glob(STELLA_LIB_HOME, 'stella', 'data', '*.rb')