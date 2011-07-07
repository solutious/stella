require 'httparty'
require 'stella'

class Stella  
  class API
    include HTTParty
    ssl_ca_file Stella::Client::SSL_CERT_PATH
    format :json
    attr_reader :httparty_opts, :response, :account, :key
    def initialize account=nil, key=nil, httparty_opts={}
      self.class.base_uri ENV['STELLA_HOST'] || 'https://www.blamestella.com/api/v2'
      @httparty_opts = httparty_opts
      @account = account || ENV['STELLA_ACCOUNT']
      @key = key || ENV['STELLA_KEY']
      unless @account.to_s.empty? || @key.to_s.empty?
        httparty_opts[:basic_auth] ||= { :username => @account, :password => @key }
      end
    end
    def get path, params=nil
      opts = httparty_opts
      opts[:query] = params || {}
      execute_request :get, path, opts
    end
    def post path, params=nil
      opts = httparty_opts
      opts[:body] = params || {}
      execute_request :post, path, opts
    end
    def site_uri path
      uri = Addressable::URI.parse self.class.base_uri
      uri.path = uri_path(path)
      uri.to_s
    end
    private
    def uri_path *args
      args.unshift ''  # force leading slash
      path = args.flatten.join('/')
      path.gsub '//', '/'
    end
    def execute_request meth, path, opts
      path = uri_path [path]
      @response = self.class.send meth, path, opts
      indifferent_params @response.parsed_response
    end
    # Enable string or symbol key access to the nested params hash.
    def indifferent_params(params)
      if params.is_a?(Hash)
        params = indifferent_hash.merge(params)
        params.each do |key, value|
          next unless value.is_a?(Hash) || value.is_a?(Array)
          params[key] = indifferent_params(value)
        end
      elsif params.is_a?(Array)
        params.collect! do |value|
          if value.is_a?(Hash) || value.is_a?(Array)
            indifferent_params(value)
          else
            value
          end
        end
      end
    end
    # Creates a Hash with indifferent access.
    def indifferent_hash
      Hash.new {|hash,key| hash[key.to_s] if Symbol === key }
    end
    
    class Unauthorized < RuntimeError
    end
  end
end

#Stella::API.debug_output $stdout
#Stella::API.base_uri 'http://localhost:3000/api/v2'
#@api = Stella::API.new