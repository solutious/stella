
require 'uri'
require 'timeout'
require 'net/http'

  module HTTPUtil
    VALID_METHODS = %w{GET HEAD POST PUT DELETE}
    @@timeout = 20
    
    # Takes a string. See WEBrick::parse_header(string).
    def HTTPUtil.parse_header(raw)
      header = Hash.new([].freeze)
      raw.each_line do |line|
        case line
        when /\A(.+?):\s+(.+)\z/om
          name, value = $1, $2 
          name = name.tr('-', '_').to_sym
          value.strip!
          
          header[name] = [] unless header.has_key?(name)
          header[name] << value
        end
      end
      header
    end
    
    # Takes a string or array. See parse_header_body for further info.
    # Returns +method+, +http_version+, +uri+, +header+, +body+
    def HTTPUtil.parse_http_request(data, host=nil, port=nil)
      return unless data && !data.empty?
      data = data.split(/\r?\n/) unless data.kind_of? Array
      data.shift while (data[0].empty? || data[0].nil?)   # Remove leading empties
      request_line = data.shift                           # i.e. GET /path HTTP/1.1
      method, path, http_version = nil
      
      # With WEBrick and other proxies, the entire URI is included in HTTP requests. 
      # i.e. GET http://stellaaahhhh.com/streetcar.png HTTP/1.1
      # The parser is expecting just the absolute path. 
      if request_line =~ /^(\S+)\s+(http:\/\/.+)\s+(HTTP.+)?/mo
        uri = URI.parse($2)
        request_line = "#{$1} #{uri.request_uri} #{$3}"
        host = uri.host
      end
      
      if request_line =~ /^(\S+)\s+(\S+)(?:\s+HTTP\/(\d+\.\d+))?/mo
        method = $1
        http_version = $3 # Comes before $2 b/c the split resets the numbered vars
        path, query_string   = $2.split('?')
        
        # We only process the header and body data when we know we're
        # starting from the beginning of a request string. We don't
        # want no partials. 
        header, body = HTTPUtil.parse_header_body(data)
        query = HTTPUtil.parse_query(method, query_string)
        
        host ||= header[:Host][0]
        host, port = host.split(':') if host.index(':')
        
        # TODO: Parse username/password
        uri = URI::HTTP.build({
          :scheme => 'http',
          :host => host.to_s, 
          :port => port || 80, 
          :path => path, 
          :query => query_string
        })
        
      else
        rl = request_line.sub(/\x0d?\x0a\z/o, '')
        raise "Bad Request-Line `#{rl}'."
      end
      
      return method, http_version, uri, header, body
    end
    
    
    # Takes a string or array. See parse_header_body for further info. 
    # Returns +status+, +http_version+, +message+, +header+, +body+
    def HTTPUtil.parse_http_response(data=[])
      return unless data && !data.empty?
      data = data.split(/\r?\n/) unless data.kind_of? Array
      data.shift while (data[0].empty? || data[0].nil?)   # Remove leading empties
      status_line = data.shift                            # ie. HTTP/1.1 200 OK
      http_version, status, message = nil
      
      if status_line =~ /^HTTP\/(\d.+?)(\s+(\d\d\d)\s+(.+))?$/mo
        http_version = $1
        status   = $2
        message   = $4
        
        header, body, query = HTTPUtil.parse_header_body(data)
        
      else  
        raise "Bad Response-Line `#{status_line}'."
      end
      
      return status, http_version, message, header, body
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
      data.shift while (data[0].nil? || data[0].empty?)   # Remove leading empties
      
      return header, body unless data && !data.empty?
      
      #puts data.to_yaml
      
      # Skip that first line if it exists
      data.shift if data[0].match(/\AHTTP|GET|POST|DELETE|PUT|HEAD/mo)
      
      header_lines = []
      header_lines << data.shift while (!data[0].nil? && !data[0].empty?)
      header = HTTPUtil::parse_header(header_lines.join($/))
      
      # We omit the blank line that delimits the header from the body
      body = data[1..-1].join($/) unless data.empty? 
      
      return header, body
    end
    
    def HTTPUtil.parse_query(request_method, query_string, content_type='', body='')
      query = Hash.new([].freeze)

        if request_method == "GET" || request_method == "HEAD"
          query = HTTPUtil::parse_query_from_string(query_string)
        elsif content_type =~ /^application\/x-www-form-urlencoded/
          query = HTTPUtil::parse_query_from_string(body)
        elsif content_type =~ /^multipart\/form-data; boundary=(.+)/
          boundary = $1.tr('"', '')
          query = HTTPUtil::parse_form_data(body, boundary)
        else
          query
        end

      query
    end
    
    def HTTPUtil.validate_method(meth='GET')
      (VALID_METHODS.member? meth.upcase) ? meth : VALID_METHODS[0]
    end
    
    # Parses a query string by breaking it up at the '&'
    # and ';' characters.  You can also use this to parse
    # cookies by changing the characters used in the second
    # parameter (which defaults to '&;'.
    # Stolen from Mongrel
    def HTTPUtil.parse_query_from_string(qs, d = '&;')
      params = {}
      (qs||'').split(/[#{d}] */n).inject(params) { |h,p|
        k, v=unescape(p).split('=',2)
        next unless k
        k = k.tr('-', '_').to_sym
        if cur = params[k]
          if cur.class == Array
            params[k] << v
          else
            params[k] = [cur, v]
          end
        else
          params[k] = v
        end
      }

      return params
    end

    
    
    # Based on WEBrick::HTTPutils::parse_form_data
    def HTTPUtil.parse_form_data(io, boundary)
      boundary_regexp = /\A--#{boundary}(--)?#{$/}\z/
      form_data = Hash.new
      return form_data unless io
      data = nil
      io.each_line{|line|
        if boundary_regexp =~ line
          if data
            data.chop!
            key = data.name.tr('-', '_').to_sym
            if form_data.has_key?(key)
              form_data[key].append_data(data)
            else
              form_data[key] = data 
            end
          end
          data = FormData.new
          next
        else
          if data
            data << line
          end
        end
      }
      return form_data
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
    

    
    # Performs URI escaping so that you can construct proper
    # query strings faster.  Use this rather than the cgi.rb
    # version since it's faster.  (Stolen from Mongrel/Camping).
    def HTTPUtil.escape(s)
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
        '%'+$1.unpack('H2'*$1.size).join('%').upcase
      }.tr(' ', '+')
    end


    # Unescapes a URI escaped string. (Stolen from Mongrel/Camping).
    def HTTPUtil.unescape(s)
      s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
        [$1.delete('%')].pack('H*')
      }
    end
    
    
  end

