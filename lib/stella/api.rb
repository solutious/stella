require 'httparty'
require 'stella'

class Stella
  class API
    include HTTParty
    base_uri 'https://www.blamestella.com/api/v2'
    ssl_ca_file Stella::Client::SSL_CERT_PATH
    format :json
    attr_reader :httparty_opts, :response
    def initialize user=nil, key=nil, httparty_opts={}
      @httparty_opts = httparty_opts.merge({
        :basic_auth => { :username => user || ENV['STELLA_USER'], :password => key || ENV['STELLA_KEY'] }
      })
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
  end
end

#Stella::API.debug_output $stdout
#Stella::API.base_uri 'http://localhost:3000/api/v2'
#@api = Stella::API.new