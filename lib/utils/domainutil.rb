
require 'net/dns/packet'

module DomainUtil

  def DomainUtil.parse_domain_request(data=[])
    return unless data && !data.empty?
    data = data.split(/\r?\n/) unless data.kind_of? Array
    data.shift while (data[0].empty? || data[0].nil?)   # Remove leading empties
    
    dns_data = Net::DNS::Packet.parse( data.join($/) )
    return unless dns_data.header.query? 
    domain_name = dns_data.question[0].qName
    return domain_name, dns_data, dns_data.header
  end
  
  def DomainUtil.parse_domain_response(data=[])
    return unless data && !data.empty?
    data = data.split(/\r?\n/) unless data.kind_of? Array
    data.shift while (data[0].empty? || data[0].nil?)   # Remove leading empties
    
    # This is the heavy lifting. 
    dns_data = Net::DNS::Packet.parse( data.join($/) )
    
    # We don't want queries or empty answers
    return if dns_data.header.query? || dns_data.answer.nil? || dns_data.answer.empty?
    
    domain_name = dns_data.answer[0].name
    
    # Empty the lists if they are already populated
    addresses = []
    cnames = []

    # Store the CNAMEs associated to this domain. Can be empty. 
    dns_data.each_cname do |cname|
      cnames << cname.to_s
    end

    # Store the IP address for this domain. If empty, the lookup was unsuccessful. 
    dns_data.each_address do |ip|
      addresses << ip.to_s
    end
    
    return domain_name, dns_data, addresses, cnames
  end

end
