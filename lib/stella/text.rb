
module Stella
  
  # Stella::Text
  #
  # This is the API for retrieving interface text in Stella. The intended use
  # is to have a single instance of this class although there's nothing stopping
  # you (or anyone else!) from having as many instances as you see fit. 
  # Currently only yaml files are supported. 
  class Text
    require 'stella/text/resource'
    
    DEFAULT_LANGUAGE = 'en'.freeze unless defined? LANGUAGE
    MESSAGE_NOT_DEFINED = "The message %s is not defined"
    RESOURCES_PATH = File.join(STELLA_HOME, "support", "text").freeze unless defined? RESOURCES_PATH
    
    attr_reader :resource, :lang
    
    def initialize(language=nil)
      @lang = determine_language(language)
      @resource = Resource.new(RESOURCES_PATH, @lang)
      @available_languages = []
    end
    
    def determine_language(language)
      return language if Text.supported_language?(language)
      Stella::LOGGER.info("There's no translation for '#{language}' yet. Maybe you can help? stella@solutious.com") if language
      language = (ENV['STELLA_LANG'] || ENV['LOCALE'] || '').split('_')[0]
      Text.supported_language?(language) ? language : DEFAULT_LANGUAGE
    end
    
    def msg(txtsym, *vars)
      return self.parse(MESSAGE_NOT_DEFINED, txtsym) unless @resource.message.has_key?(txtsym)
      parse(@resource.message[txtsym], vars)
    end

    def err(txtsym, *vars)
      return self.parse(MESSAGE_NOT_DEFINED, txtsym) unless @resource.error.has_key?(txtsym)
      parse(@resource.error[txtsym], vars)
    end

    def parse(text, vars)
      sprintf(text, *vars)
    end
    
    def self.supported_language?(language)
      return File.exists?(File.join(RESOURCES_PATH, "#{language}.yaml"))
    end
    
    def available_languages
      #return @available_languages unless @available_languages.empty?
      translations = Dir.glob(File.join(RESOURCES_PATH, "*.yaml"))
      translations.each do |path|
        trans = YAML.load_file(path)
        next if !trans || trans.empty? || !trans[:info] || !trans[:info][:enabled]
        @available_languages << trans[:info]
      end
      @available_languages
    end
    
  end
  
  
end