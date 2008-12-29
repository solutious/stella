require 'net/http'
require 'uri'
require 'timeout'

  module HTTPUtil
    VALID_METHODS = %w{GET HEAD POST PUT DELETE}
    @@timeout = 20
    
    def HTTPUtil.hostname(tmp_uri)
      return if tmp_uri.empty?
      uri = URI.parse(tmp_uri) if tmp_uri.is_a? String
      
      #STDERR.puts "Hostname for #{ uri.port }"
      uri.host
    end
    
    # Normalize all URIs before they are used for anything else
    def HTTPUtil.normalize(uri_str, scheme = true) 
      
      
      #STDERR.puts "  BEFORE: " << uri_str
      if (!uri_str.index(/^https?:\/\//))
        uri_str = 'http://' << uri_str
      end
      #STDERR.puts "   AFTER: " << uri_str
      
      uri_str.gsub!(/\s/, '%20')
      
      uri = URI.parse(uri_str)
      
      uri_clean = ""
      
      # TODO: use URI.to_s instead of manually creating the string
      
      if (scheme)
        uri_clean << uri.scheme.to_s + '://'  
      end
      
        
      if (!uri.userinfo.nil?)
        uri_clean << uri.userinfo.to_s
        uri_clean << '@'
      end
      
      #uri.host.gsub!(/^www\./, '')
      
      uri_clean << uri.host.to_s
      
      if (!uri.port.nil? && uri.port != 80 && uri.port != 443)
        uri_clean << ':' + uri.port.to_s
      end
      
      
      
      if (!uri.path.nil? && !uri.path.empty?)
        uri_clean << uri.path
      elsif
        uri_clean << '/'
      end
      
      
      if (!uri.query.nil? && !uri.path.empty?)
        uri_clean << "?" << uri.query
      end
      
      #STDERR.puts "IN: " << uri_str
      #STDERR.puts "OUT: " << uri_clean
      
      uri_clean
    end
    
    def HTTPUtil.fetch_content(uri, limit = 10)
      res = self.fetch(uri,limit)
      return (res) ? res.body : ""
    end
    
    def HTTPUtil.fetch(uri, limit = 10)
       
      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0
      STDERR.puts "URL: #{uri.to_s}"
      uri = URI.parse(uri) if uri.is_a? String
      
      begin
        timeout(@@timeout) do
          response = Net::HTTP.get_response(uri)
        
        
          case response
          when Net::HTTPSuccess     then response
          when Net::HTTPRedirection then fetch(response['location'], limit - 1)
          else
            STDERR.puts "Not found: " << uri.to_s
          end
        end
      rescue TimeoutError
        STDERR.puts "Net::HTTP timed out for " << uri.to_s
        return
      rescue => ex
        STDERR.puts "Error: #{ex.message}"
      end
    
    end
    
    def HTTPUtil.post(uri, params = {}, limit = 10)
       
      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0
      
      uri = URI.parse(uri) if uri.is_a? String
      
      begin
        timeout(@@timeout) do
           response = Net::HTTP.post_form(uri, params)
        
          case response
          when Net::HTTPSuccess     then response
          when Net::HTTPRedirection then fetch(response['location'], limit - 1)
          else
            STDERR.puts "Error for " << uri.to_s
            STDERR.puts response.body
          end
        end
      rescue TimeoutError
        STDERR.puts "Net::HTTP timed out for " << uri.to_s
        return
      end
      
      
      
    end
    
    def HTTPUtil.exists(uri)
      
      begin
        response = fetch(uri)
        case response
        when Net::HTTPSuccess     then true
        when Net::HTTPRedirection then fetch(response['location'], limit - 1)
        else
          false
        end
        
      rescue Exception => e
        STDERR.puts "Problem: " + e.message
        false
      end
      
    end
    
    def HTTPUtil.parse_query(query)
      params = Hash.new([].freeze)

      query.split(/[&;]/n).each do |pairs|
        key, value = pairs.split('=',2).collect{|v| URI.unescape(v) }
        if params.has_key?(key)
          params[key].push(value)
        else
          params[key] = [value]
        end
      end

      params
    end
    
    def HTTPUtil.validate_method(meth='GET')
      meth = (VALID_METHODS.member? meth.upcase) ? meth : VALID_METHODS[0]
    end
    
    # Extend the basic query string parser provided by the cgi module.
    # converts single valued params (the most common case) to
    # objects instead of arrays
    #
    # Input:
    # the query string
    #
    # Output:
    # hash of parameters, contains arrays for multivalued parameters
    # (multiselect, checkboxes , etc)
    # If no query string is provided (nil or "") returns an empty hash.

    def HTTPUtil.query_to_hash(query_string)
      return {} unless query_string

      query_parameters = HTTPUtil.parse_query(query_string)

      query_parameters.each { |key, val|
        # replace the array with an object
        query_parameters[key] = val[0] if 1 == val.length
      }

      # set default value to nil! cgi sets this to []
      query_parameters.default = nil

      return query_parameters
    end
    
    def HTTPUtil.hash_to_query(parameters)
      return '' unless parameters
      pairs = []
      parameters.each do |param, value|
        pairs << "#{param}=#{URI.escape(value.to_s)}"
      end
      return pairs.join('&')
      #return pairs.join(";")
    end
    
    
  end

