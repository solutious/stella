

module Stella::Data
  class DomainRequest < Stella::Storable
    attr_accessor :time, :client_ip, :server_ip, :dns_data, :domain_name, :header
    attr_reader :raw_data
 
    def initialize(raw_data)
      @raw_data = raw_data
      @dns_data, @domain_name, @header = DomainUtil::parse_domain_request(@raw_data)
    end
    
    def field_names
      [ :time, :client_ip, :server_ip, :domain_name, :header ]
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
  
  class DomainResponse < Stella::Storable
    attr_accessor :time, :client_ip, :server_ip, :dns_data, :domain_name, :header, :addresses, :cnames
    attr_reader :raw_data
 
    def initialize(raw_data)
      @raw_data = raw_data
      @dns_data, @domain_name, @header, @addresses, @cnames = DomainUtil::parse_domain_response(@raw_data)
    end
    
    def field_names
      [ :time, :client_ip, :server_ip, :dns_data, :domain_name, :header, :addresses, :cnames ]
    end
    
    def to_s
      "%s: %s <- %s (%s) %s" % [@time, @client_ip, @server_ip, @domain_name, (@addresses || []).join(',')]
    end
    
    def inspect
      str =  "#{$/};; RESPONSE        #{@time.to_s}"
      str << "#{$/};; %s <%s %s" % [@client_ip, '-'*30, @server_ip]
      str << "#{$/};;#{$/}"
      str << @dns_data.inspect
    end
  end
end