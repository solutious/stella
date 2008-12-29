


module Stella 
  class CLI
    class Language < Stella::CLI::Base
      
      
      def run
        languages = Stella::TEXT.available_languages 
        puts Stella::TEXT.msg(:text_available_languages, languages.map { |l| "#{l[:language]} " })
      end
      
    end
    
    @@commands['lang'] = Stella::CLI::Language
  end
end