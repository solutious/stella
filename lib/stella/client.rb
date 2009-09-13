require "observer"
require "tempfile"
require 'httpclient'
require 'nokogiri'

module Stella
  class Client
    include Observable
    attr_reader :client_id
    attr_accessor :base_uri
    attr_accessor :proxy
    
    class Container
      attr_accessor :response
      def doc
        if @response.header['Content-Type'] == ['text/html']
          Nokogiri::HTML(body.content)
        end
      end

      def body; @response.body; end
      def headers; @response.header; end
      alias_method :header, :headers
      def status; @response.status; end
      
      
    end
    
    def initialize(base_uri=nil, client_id=1)
      @base_uri, @client_id = base_uri, client_id
      @cookie_file = Tempfile.new('stella-cookie')
    end
    
    def find_replacement_value(name, container, params)
      value = nil
      Stella.ld "REPLACE: #{name}"
      Stella.ld "IVARS: #{container.instance_variables}"
      Stella.ld "PARAMS: #{params.inspect}"
      container.instance_variables.each { |var|
        if var.to_s == "@#{name}"
          value = container.instance_variable_get("@#{name}") 
          break
        end
      }
      value = params[name.to_sym] if value.nil?
      value
    end
    
    def execute(usecase)
      http_client = generate_http_client
      container = Container.new
      usecase.requests.each do |req|
        uri = base_uri.to_s
        uri.gsub! /\/$/, '';
        request_uri = req.uri.to_s
        
        # TODO: Use scan instead
        if a = request_uri.match(/:([a-z_]+)/i)
          val = find_replacement_value(a[1], container, req.params)
          unless val.nil?
            Stella.ld "FOUND: #{val}"
            request_uri.gsub! /:#{a[1]}/, val
          end
        end
        
        uri << request_uri
        meth = req.http_method.to_s.downcase
        Stella.ld "#{meth}: " << "#{uri} " << req.params.inspect
        container.response = http_client.send(meth, uri, req.params)
        
        if req.response.has_key? container.status
          begin
            container.instance_eval &req.response[container.status] 
          rescue => ex
            Stella.le "Error in response block:", ex.message
            Stella.ld ex.backtrace
          end
        end
        sleep req.wait if req.wait
      end
    end
    
  private
    def generate_http_client
      if @proxy
        http_client = HTTPClient.new(@proxy.uri)
        http_client.set_proxy_auth(@proxy.user, @proxy.pass) if @proxy.user
      else
        http_client = HTTPClient.new
      end
      http_client.set_cookie_store @cookie_file.to_s
      http_client
    end
    
  end
end