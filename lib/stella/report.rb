
class Stella
  class Report
    @plugins = {}
    class << self
      attr_reader :plugins
      def plugin?(name)
        @plugins.has_key? name
      end
      def load(name)
        @plugins[name]
      end
    end
    module Plugin
      def self.included(obj)
        obj.extend ClassMethods
      end
      def processed!
        @processed = true
      end
      def processed?
        @processed == true
      end
      module ClassMethods
        attr_reader :plugin
          def register(plugin)
          @plugin = plugin
          Stella::Report.plugins[plugin] = self
        end
        def process *args
          raise StellaError, "Must override run"
        end
      end
    end

    class Headers < StellaObject
      include Report::Plugin
      field :request_headers
      field :response_headers
      def process(timeline)
        log = timeline.messages.filter(:kind => :http_log)
        return if log.empty?
        @request_headers = log.first.request_headers
        @response_headers = log.first.response_headers
        processed!
      end
      register :headers
    end
    
    class Content < StellaObject
      include Report::Plugin
      field :request_body
      field :response_body
      def process(timeline)
        log = timeline.messages.filter(:kind => :http_log)
        return if log.empty?
        @request_body = log.first.request_body
        @response_body = log.first.response_body
        processed!
      end
      register :content
    end
    
    class Metrics < StellaObject
      include Report::Plugin
      field :response_time
      field :socket_connect
      field :first_byte
      field :send_request
      field :receive_response
      field :page_size
      def process(timeline)
        @response_time = timeline.stats.group(:response_time).merge
        @socket_connect = timeline.stats.group(:socket_connect).merge
        @first_byte = timeline.stats.group(:first_byte).merge
        @send_request = timeline.stats.group(:send_request).merge
        @receive_response = timeline.stats.group(:receive_response).merge
        log = timeline.messages.filter(:kind => :http_log)
        unless log.empty?
          @page_size = log.first.response_body.size
        end
        processed!
      end
      register :metrics
    end
    
    attr_reader :section, :timeline
    def initialize(timeline)
      @timeline = timeline
      @section = {}
      @processed = false
    end
    def process
      self.class.plugins.each_pair do |name,klass|
        Stella.ld "processing #{name}"
        plugin = klass.new
        plugin.process(timeline)
        @section[name] = plugin
      end

      #
      ##p thread.timeline.messages.filter(:kind => :exception)
      ##p thread.timeline.messages.filter(:kind => :timeout)
      #

      @processed = true
    end
    def processed?
      @processed == true
    end
  end
end