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
      field :uri     
      field :request_params
      field :request_headers
      field :request_body
      field :response_status
      field :response_headers
      field :response_body
      field :msg
    end
  end
  class Report < StellaObject
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
        obj.field :processed => Boolean
      end
      def processed!
        @processed = true
      end
      def processed?
        @processed == true
      end
      attr_reader :timeline
      def initialize(timeline=nil)
        @timeline = timeline
      end
      module ClassMethods
        attr_reader :plugin
        def register(plugin)
          @plugin = plugin
          extra_methods = eval "#{self}::ReportMethods" rescue nil
          Stella::Report.send(:include, extra_methods) if extra_methods
          Stella::Report.field plugin => self
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
        @exceptions = timeline.messages.filter(:state => :exception)
        @timeouts = timeline.messages.filter(:state => :timeout)
        processed!
      end
      def exceptions?
        !@exceptions.empty?
      end
      def timeouts?
        !@timeouts.empty?
      end
      def all 
        [@exceptions, @timeouts].flatten
      end
      module ReportMethods
        # expects Statuses plugin is loaded
        def errors?
          exceptions? || timeouts? || !statuses.nonsuccessful.empty?
        end
        def exceptions?
          return false unless processed? && errors
          errors.exceptions?
        end
        def timeouts?
          return false unless processed? && errors
          errors.timeouts?
        end
      end
      register :errors
    end
    
    class Statuses < StellaObject
      include Report::Plugin
      field :values => Array
      def process(filter={})
        log = timeline.messages.filter(:kind => :http_log)
        @values = log.collect { |entry| entry.tag_values(:status) }.flatten
        processed!
      end
      def nonsuccessful
        @values.select { |status| status.to_i >= 400 }
      end
      def successful
        @values.select { |status| status.to_i < 400 }
      end
      def success?
        nonsuccessful.empty?
      end
      module ReportMethods
        def success?
          statuses.success?
        end
        def statuses_pretty
          pretty = ["Statuses"]
          if statuses.successful.size > 0
            pretty << '%20s: %s' % ['successful', statuses.successful.join(', ')] 
          end
          if statuses.nonsuccessful.size > 0
            pretty << '%20s: %s' % ['nonsuccessful', statuses.nonsuccessful.join(', ')] 
          end
          pretty.join $/
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
      field :is_binary => Boolean
      field :is_image => Boolean
      def binary?
        @is_binary == true
      end
      def image?
        @is_image == true
      end
      def process(filter={})
        log = timeline.messages.filter(:kind => :http_log)
        return if log.empty?
        unless Stella::Utils.binary?(log.first.request_body) || Stella::Utils.image?(log.first.request_body)
          @request_body = log.first.request_body 
        end
        @request_body_digest = log.first.request_body.digest
        @is_binary = Stella::Utils.binary?(log.first.response_body)
        @is_image = Stella::Utils.image?(log.first.response_body)
        unless binary? || image?
          @response_body = log.first.response_body.to_s
          if @response_body.size >= 250_000
            @response_body = @response_body.slice 0, 249_999
            @response_body << ' [truncated]'
          end
          @response_body.force_encoding("UTF-8") if RUBY_VERSION >= "1.9.0"
        end
        @response_body_digest = log.first.response_body.digest
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
          puts ex.message
          # /Library/Ruby/Gems/1.8/gems/nokogiri-1.4.1/lib/nokogiri/xml/fragment_handler.rb:37: [BUG] Segmentation fault
          #  ruby 1.8.7 (2008-08-11 patchlevel 72) [universal-darwin10.0]
        end
        processed!
      end
      module ReportMethods
        def content2(name)
          return unless @section[:content] && @section[:content].respond_to?(name)
          @section[:content].send(name)
        end
      end
      register :content
    end
    
    class Metrics < StellaObject
      include Report::Plugin
      field :response_time            => Benelux::Stats::Calculator
      field :socket_connect           => Benelux::Stats::Calculator
      field :first_byte               => Benelux::Stats::Calculator
      field :last_byte                => Benelux::Stats::Calculator
      field :send_request             => Benelux::Stats::Calculator
      field :request_headers_size     => Benelux::Stats::Calculator
      field :request_content_size     => Benelux::Stats::Calculator
      field :response_headers_size    => Benelux::Stats::Calculator
      field :response_content_size    => Benelux::Stats::Calculator
      def process(filter={})
        return if processed?
        @response_time = timeline.stats.group(:response_time).merge
        @socket_connect = timeline.stats.group(:socket_connect).merge
        @first_byte = timeline.stats.group(:first_byte).merge
        @send_request = timeline.stats.group(:send_request).merge
        @last_byte = timeline.stats.group(:last_byte).merge
        #@response_time2 = Benelux::Stats::Calculator.new 
        #@response_time2.sample @socket_connect.mean + @send_request.mean + @first_byte.mean + @last_byte.mean
        log = timeline.messages.filter(:kind => :http_log)
        @request_headers_size = Benelux::Stats::Calculator.new 
        @request_content_size = Benelux::Stats::Calculator.new 
        @response_headers_size = Benelux::Stats::Calculator.new 
        @response_content_size = Benelux::Stats::Calculator.new 
        unless log.empty?
          log.each do |entry|
            @request_headers_size.sample entry.request_headers.size
            @request_content_size.sample entry.request_body.size
            @response_headers_size.sample entry.response_headers.size
            @response_content_size.sample entry.response_body.size
          end
        end
        processed!
      end
      def postprocess
        self.class.field_names.each do |fname|
          next unless self.class.field_types[fname] == Benelux::Stats::Calculator
          hash = send(fname)
          val = Benelux::Stats::Calculator.from_hash hash
          send("#{fname}=", val)
        end
      end
      module ReportMethods
        def metrics_pretty
          return unless metrics
          pretty = ['Metrics']
          [:socket_connect, :send_request, :first_byte, :last_byte, :response_time].each do |fname|
            val = metrics.send(fname)
            pretty << ('%20s: %8sms' % [fname.to_s.tr('_', ' '), val.mean.to_ms])
          end
          pretty << ''
          [:request_headers_size, :response_content_size].each do |fname|
            val = metrics.send(fname)
            pretty << ('%20s: %8s' % [fname.to_s.tr('_', ' '), val.mean.to_bytes])
          end
          pretty.join $/
        end
      end
      register :metrics
    end
    
    field :processed => Boolean
    
    attr_reader :timeline, :filter
    def initialize(timeline=nil, filter={})
      @timeline, @filter = timeline, filter
      @processed = false
    end
    def postprocess
      self.class.plugins.each_pair do |name,klass|
        val = klass.from_hash(self.send(name))
        self.send("#{name}=", val)
      end
    end
    def process
      self.class.plugins.each_pair do |name,klass|
        Stella.ld "processing #{name}"
        plugin = klass.new timeline
        plugin.process(filter)
        self.send("#{name}=", plugin)
      end
      @processed = true
    end
    def processed?
      @processed == true
    end
  end
end