begin
  require 'pismo'
rescue LoadError
end

class Stella
  class Log
    class HTTP < StellaObject
      include Selectable::Object
      field :stamp
      field :httpmethod
      field :httpstatus
      field :uri     
      field :request_params
      field :request_headers
      field :request_body
      field :response_headers
      field :response_body
    end
  end
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
      attr_reader :timeline
      def initialize(timeline)
        @timeline = timeline
      end
      module ClassMethods
        attr_reader :plugin
        def register(plugin)
          @plugin = plugin
          extra_methods = eval "#{self}::ReportMethods" rescue nil
          Stella::Report.send(:include, extra_methods) if extra_methods
          Stella::Report.plugins[plugin] = self
        end
        def process *args
          raise StellaError, "Must override run"
        end
      end
    end

    class Errors < StellaObject
      include Report::Plugin
      field :exceptions
      field :timeouts
      def process(filter={})
        @exceptions = timeline.messages.filter(:kind => :exception)
        @timeouts = timeline.messages.filter(:kind => :timeout)
        processed!
      end
      def errors?
        !@exceptions.empty? || !@timeouts.empty?
      end
      def all 
        [@exceptions, @timeouts].flatten
      end
      module ReportMethods
        # expects Statuses plugin is loaded
        def errors?
          return false unless processed?
          errstatus = statuses.select { |status| status.to_i >= 400 }
          @section[:errors].errors? || !errstatus.empty?
        end
      end
      register :errors
    end
    
    class Statuses < StellaObject
      include Report::Plugin
      field :statuses => Array
      def process(filter={})
        log = timeline.messages.filter(:kind => :http_log)
        @statuses = log.collect { |entry| entry.tag_values(:status) }.flatten
        processed!
      end
      module ReportMethods
        def statuses
          return false unless processed?
          @section[:statuses].statuses
        end
      end
      register :statuses
    end
    
    class Headers < StellaObject
      include Report::Plugin
      field :request_headers
      field :response_headers
      field :request_headers_digest
      field :response_headers_digest
      def process(filter={})
        log = timeline.messages.filter(:kind => :http_log)
        return if log.empty?
        @request_headers = log.first.request_headers
        @response_headers = log.first.response_headers
        @request_headers_digest = log.first.request_headers.digest
        @response_headers_digest = log.first.response_headers.digest
        processed!
      end
      register :headers
    end
    
    class Content < StellaObject
      include Report::Plugin
      field :request_body
      field :response_body
      field :request_body_digest
      field :response_body_digest
      field :keywords => Array
      field :title
      field :favicon
      field :author
      field :lede
      field :description
      def process(filter={})
        log = timeline.messages.filter(:kind => :http_log)
        return if log.empty?
        @request_body = log.first.request_body
        @request_body_digest = log.first.request_body.digest
        @response_body = log.first.response_body
        @response_body.force_encoding("UTF-8") if RUBY_VERSION >= "1.9.0"
        @response_body_digest = @response_body.digest
        begin 
          if defined?(Pismo) && @response_body
            doc = Pismo::Document.new @response_body
            @keywords = doc.keywords
            @title = doc.title
            @favicon = doc.favicon
            @author = doc.author
            @lede = doc.lede
            @description = doc.description
          end
        rescue => ex
          # /Library/Ruby/Gems/1.8/gems/nokogiri-1.4.1/lib/nokogiri/xml/fragment_handler.rb:37: [BUG] Segmentation fault
          #  ruby 1.8.7 (2008-08-11 patchlevel 72) [universal-darwin10.0]
        end
        processed!
      end
      module ReportMethods
        def content(name)
          return unless @section[:content] && @section[:content].respond_to?(name)
          @section[:content].send(name)
        end
      end
      register :content
    end
    
    class Metrics < StellaObject
      include Report::Plugin
      field :response_time
      field :socket_connect
      field :first_byte
      field :last_byte
      field :send_request
      field :request_headers_size
      field :request_body_size
      field :response_headers_size
      field :response_body_size
      def process(filter={})
        @response_time = timeline.stats.group(:response_time).merge
        @socket_connect = timeline.stats.group(:socket_connect).merge
        @first_byte = timeline.stats.group(:first_byte).merge
        @send_request = timeline.stats.group(:send_request).merge
        @last_byte = timeline.stats.group(:last_byte).merge
        #@response_time2 = Benelux::Stats::Calculator.new 
        #@response_time2.sample @socket_connect.mean + @send_request.mean + @first_byte.mean + @last_byte.mean
        log = timeline.messages.filter(:kind => :http_log)
        @request_headers_size = Benelux::Stats::Calculator.new 
        @request_body_size = Benelux::Stats::Calculator.new 
        @response_headers_size = Benelux::Stats::Calculator.new 
        @response_body_size = Benelux::Stats::Calculator.new 
        unless log.empty?
          log.each do |entry|
            @request_headers_size.sample entry.request_headers.size
            @request_body_size.sample entry.request_body.size
            @response_headers_size.sample entry.response_headers.size
            @response_body_size.sample entry.response_body.size
          end
        end
        processed!
      end
      module ReportMethods
        def metric(name)
          return unless @section[:metrics] && @section[:metrics].respond_to?(name)
          @section[:metrics].send(name)
        end
        def metrics_pretty
          return unless @section[:metrics]
          pretty = ['Metrics']
          [:socket_connect, :send_request, :first_byte, :last_byte, :response_time].each do |fname|
            val = @section[:metrics].send(fname)
            pretty << ('%20s: %5sms' % [fname.to_s.tr('_', ' '), val.mean.to_ms])
          end
          pretty << ''
          [:request_headers_size, :response_body_size].each do |fname|
            val = @section[:metrics].send(fname)
            pretty << ('%20s: %8s' % [fname.to_s.tr('_', ' '), val.mean.to_bytes])
          end
          pretty.join $/
        end
      end
      register :metrics
    end
    
    attr_reader :section, :timeline, :filter
    def initialize(timeline, filter={})
      @timeline, @filter = timeline, filter
      @section = {}
      @processed = false
    end
    def process
      self.class.plugins.each_pair do |name,klass|
        Stella.ld "processing #{name}"
        plugin = klass.new timeline
        plugin.process(filter)
        @section[name] = plugin
      end
      @processed = true
    end
    def to_yaml
      @section.to_yaml
    end
    def to_json
      if YAJL_LOADED
        Yajl::Encoder.encode(@section)
      elsif JSON_LOADED
        obj.to_json
      else
        raise "no JSON parser loaded"
      end
    end
    def processed?
      @processed == true
    end
  end
end