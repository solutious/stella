

module Stella
  
  class Text
    class Resource
      require 'yaml'
      
      attr_reader :lang, :country, :encoding
      attr_reader :messages, :path
      
      def initialize(path, lang)
        @path = path
        @lang = lang
        @messages = {}
        load_resource
      end
      
      def path
        File.join(@path, "#{@lang}.yaml")
      end
      
      def load_resource
        return @messages unless @messages.empty?
        Stella::LOGGER.debug("LOADING #{path}")
        raise UnsupportedLanguage unless File.exists?(path)
        @messages = YAML.load_file(path)
      end
      
      def messages
        @messages
      end
        alias :message :messages
        alias :error :messages
      
    end
  end
  
end