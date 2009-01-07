
require 'uri'
require 'timeout'
require 'net/http'
require 'webrick/httputils'

  module HTTPUtil
    VALID_METHODS = %w{GET HEAD POST PUT DELETE}
    @@timeout = 20
    
    # Takes a string. See WEBrick::parse_header(string).
    def HTTPUtil.parse_header(string)
      return WEBrick::HTTPUtils::parse_header(string)
    end
    
    # Takes a string or array. See parse_header_body for further info.
    # Returns +method+, +path+, +http_version+, +header+, +body+
    def HTTPUtil.parse_http_request(data=[])
      return unless data && !data.empty?
      data = data.split(/\r?\n/) unless data.kind_of? Array
      data.shift while (data[0].empty? || data[0].nil?)   # Remove leading empties
      request_line = data.shift                           # i.e. GET /path HTTP/1.1
      method, path, http_version = nil
      
      if request_line =~ /^(\S+)\s+(\S+)(?:\s+HTTP\/(\d+\.\d+))?/mo
        method = $1
        path   = $2
        http_version   = $3 || '0.9'
        
        # We only process the header and body data when we know we're
        # starting from the beginning of a request string. We don't
        # want no partials. 
        header, body = HTTPUtil.parse_header_body(data)
      else
        rl = request_line.sub(/\x0d?\x0a\z/o, '')
        raise "Bad Request-Line `#{rl}'."
      end
      
      return method, path, http_version, header, body
    end
    
    
    # Takes a string or array. See parse_header_body for further info. 
    # Returns +http_version+, +status+, +message+, +header+, +body+
    def HTTPUtil.parse_http_response(data=[])
      return unless data && !data.empty?
      data = data.split(/\r?\n/) unless data.kind_of? Array
      data.shift while (data[0].empty? || data[0].nil?)   # Remove leading empties
      status_line = data.shift                            # ie. HTTP/1.1 200 OK
      http_version, status, message = nil
      
      if status_line =~ /^HTTP\/(\d.+?)\s+(\d\d\d)\s+(.+)$/mo
        http_version = $1
        status   = $2
        message   = $3 || '0.9'
        
        header, body = HTTPUtil.parse_header_body(data)
        
      else  
        raise "Bad Response-Line `#{status_line}'."
      end
      
      return http_version, status, message, header, body
    end
    
    # Process everything after the first line of an HTTP request or response:
    # GET / HTTP/1.1
    # HTTP/1.1 200 OK
    # etc...
    # Used by parse_http_request and parse_http_response but can be used separately. 
    # Takes a string or array of strings. A string should be formatted like an HTTP 
    # request or response. If a body is present it should be separated by two newlines.
    # An array of string should contain an empty or nil element between the header 
    # and body content. This will happen naturally if the raw lines were split by 
    # a single line terminator. (i.e. /\n/ rather than /\n\n/)
    # Returns header (hash), body (string)
    def HTTPUtil.parse_header_body(data=[])
      header, body = {}, nil
      data = data.split(/\r?\n/) unless data.kind_of? Array
      data.shift while (data[0].empty? || data[0].nil?)   # Remove leading empties
      return header, body unless data && !data.empty?
      
      #puts data.to_yaml
      
      # Skip that first line if it exists
      data.shift if data[0].match(/\AHTTP|GET|POST|DELETE|PUT|HEAD/mo)
      
      begin
        header_lines = []
        header_lines << data.shift while (!data[0].nil? && !data[0].empty?)
        header = HTTPUtil::parse_header(header_lines.join($/))
        
        
        # We omit the blank line that delimits the header from the body
        body = data[1..-1].join($/) unless data.empty? 
        
      rescue => ex
        raise ex.message
      end
      
      return header, body
    end
    
    def HTTPUtil.parse_query(request_method, query_string, body)
      query = Hash.new([].freeze)
      begin
        if request_method == "GET" || request_method == "HEAD"
          query = WEBrick::HTTPUtils::parse_query(query_string)
        elsif self['content-type'] =~ /^application\/x-www-form-urlencoded/
          query = WEBrick::HTTPUtils::parse_query(body)
        elsif self['content-type'] =~ /^multipart\/form-data; boundary=(.+)/
          boundary = HTTPUtils::dequote($1)
          query = WEBrick::HTTPUtils::parse_form_data(body, boundary)
        else
          query
        end
      rescue => ex
        raise WEBrick::HTTPStatus::BadRequest, ex.message
      end
    end
    
    def HTTPUtil.validate_method(meth='GET')
      (VALID_METHODS.member? meth.upcase) ? meth : VALID_METHODS[0]
    end
    
    def HTTPUtil.parse_query_from_string(query)
      WEBrick::HTTPUtils::parse_query(query)
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

