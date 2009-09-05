

module Stella::Data::HTTP
  
  # TODO: Implement HTTPHeaders. We should be printing untouched headers. 
  # HTTPUtil should split the HTTP event lines and that's it. Replace 
  # parse_header_body with split_header_body
  class Headers < Storable
    attr_reader :raw_data
    
    def to_s
      @raw_data
    end
    
  end
  
  
end