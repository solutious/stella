

module Stella::Data
  class DomainRequest < Storable
    attr_accessor :dns_data
    attr_reader :raw_data
    
    field :time => DateTime
    field :client_ip => String
    field :server_ip => String
    field :domain_name => String
    field :header => String
    
    def initialize(raw_data)
      @raw_data = raw_data
      @dns_data, @domain_name, @header = DomainUtil::parse_domain_request(@raw_data)
    end
    
    def has_request?
      false
    end
    def has_response?
      false
    end
    def has_body?
      false
    end
    
    def to_s
      "%s: %s -> %s (%s)" % [@time, @client_ip, @server_ip, @domain_name]
    end
    
    def inspect
      str = "#{$/};; REQUEST         #{@time.to_s}"
      str << "#{$/};; %s %s> %s" % [@client_ip, '-'*30, @server_ip]
      str << "#{$/};;#{$/}"
      str << @dns_data.inspect
      str
    end
    
  end
  
  class DomainResponse < Storable
    attr_accessor :dns_data
    attr_reader :raw_data
    
    field :time => DateTime
    field :client_ip => String
    field :server_ip => String
    field :domain_name => String
    field :header => String
    field :addresses => Array
    field :cnames => Array
 
 
    def initialize(raw_data)
      @raw_data = raw_data
      @dns_data, @domain_name, @header, @addresses, @cnames = DomainUtil::parse_domain_response(@raw_data)
    end
    
    def has_request?
      false
    end
    def has_response?
      false
    end
    def has_body?
      false
    end
    
    def to_s
      "%s: %s <- %s (%s) %s" % [@time, @client_ip, @server_ip, @domain_name, (@addresses || []).join(',')]
    end
    
    def inspect
      str =  "#{$/};; RESPONSE        #{@time.strftime(NICE_TIME_FORMAT)}"
      str << "#{$/};; %s <%s %s" % [@client_ip, '-'*30, @server_ip]
      str << "#{$/};;#{$/}"
      str << @dns_data.inspect
    end
  end
end