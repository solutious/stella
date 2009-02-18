

module Stella
  module Common
    class Auth
      attr_accessor :type
      attr_accessor :user
      attr_accessor :pass
      attr_accessor :port
      def initialize(type, user, pass=nil, port=nil)
        @uri = type
        @user = user
        @pass = pass if pass
        @port = port if port
      end
    end
    class Proxy 
      attr_accessor :uri
      attr_accessor :user
      attr_accessor :pass
      def initialize(uri, user=nil, pass=nil)
        @uri = uri
        @user = user if user
        @pass = pass if pass
      end
    end
    class Machine
      attr_accessor :host
      attr_accessor :port
      attr_accessor :role
      attr_accessor :ssh
      
      def initialize(*args)
        raise "You must at least a hostname or IP address" if args.empty?
        if args.first.is_a? String
          @host, @port = args.first.split(":") 
        else  
          @host, @port, @role = args.flatten
        end
        @role ||= "app"
        @port = @port.to_i if @port
      end
      def to_s
        str = "#{@host}"
        str << ":#{@port}" if @port
        str
      end
    end
  end
end



