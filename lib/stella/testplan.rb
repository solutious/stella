

class Stella
  
  class Testplan < StellaObject
    field :id                 => Gibbler::Digest, &gibbler_id_processor
    field :userid             => String
    field :usecases           => Array
    field :desc               => String
    gibbler :userid, :usecases
    def initialize(uri=nil)
      preprocess
      if uri
        req = Stella::TP::RequestTemplate.new :get, uri
        @usecases << Stella::TP::Usecase.new(req) 
      end
    end
    def preprocess
      @usecases ||= []
    end
    def first_request
      return if @usecases.empty?
      @usecases.first.requests.first
    end
    def freeze
      return if frozen?
      @usecases.each { |uc| uc.freeze }
      @id ||= self.digest
      super
      self
    end
    
    class Usecase < StellaObject
      field :id                 => Gibbler::Digest, &gibbler_id_processor
      field :desc             => String
      field :ratio            => Float
      field :requests         => Array
      gibbler :requests
      def initialize(req=nil)
        preprocess
        @requests << req if req
      end
      def preprocess
        @requests ||= []
      end
      def freeze
        return if frozen?
        @requests.each { |r| r.freeze }
        @id ||= self.digest
        super
        self
      end
    end
    
    class EventTemplate < StellaObject
    end
    
    class RequestTemplate < EventTemplate
      field :id                 => Gibbler::Digest, &gibbler_id_processor
      field :protocol       => Symbol
      field :http_method
      field :http_version
      field :http_auth
      field :uri
      field :params           => Array
      field :headers          => Array
      field :body
      field :desc
      field :wait             => Range
      field :response_handler => Hash
      gibbler :http_method, :uri, :http_version, :params, :headers, :body
      def initialize(meth, uri)
        @protocol = :http
        @http_method, @uri = meth, uri
      end
      def freeze
        return if frozen?
        self.id ||= self.digest
        super
        self
      end
    end
    
    UC = Usecase
    RT = RequestTemplate
  end
  TP = Testplan
end