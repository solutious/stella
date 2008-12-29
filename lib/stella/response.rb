


module Stella
  
  # An object for HTTP response content
  #
  class Response < Storable
    attr_accessor :errors, :content, :messages
    attr_writer :success
    
    def initialize
      @success = false
      @errors = []
      @messages = []
      @content = {}
    end
    
    def success?
      @success
    end
    
    def add(key, value)
      @content[key] = value
    end
    
    def get(key)
      @content[key] if @content.has_key? key
    end
    
    def message(msg)
      @messages.push(msg)
    end
    
    def error(msg)
      @errors.push(msg)
    end
    
    def output(format='yaml')
      format = 'yaml' unless self.respond_to? "output_#{format}"
      #STDERR.puts "OUTPUT: #{format}"
      self.send("output_#{format}")
    end
    
    def to_hash    
      h = {}
      h[:version] = API_VERSION
      h[:errors] = @errors unless @errors.empty?
      h[:messages] = @messages unless @messages.empty?
      h[:content] = @content || {}
      h[:success] = @success || false
      h
    end
    
    def output_zip
      output = @content
    end
    
    def output_yaml
      to_hash.to_yaml
    end
    
    # http://evang.eli.st/blog/2007/2/22/my-rails-gotcha-custom-to_xml-in-a-hash-or-array
    # http://api.rubyonrails.org/classes/ActiveRecord/XmlSerialization.html#M000910
    def output_xml
      output = "<StellaResponse success=\":[\">\n"
      output << "<todo>implement XML</todo>\n"
      output << "</StellaResponse>\n"
    end
    
    def output_json
      to_hash.to_json
    end
    
    def output_html
     "hello!"
    end
    
  end
  
end

