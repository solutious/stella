module Stella::Data::HTTP

  class Body < Storable
    field :content_type
    field :form_param
    field :content
    
    def has_content?
      !@content.nil?
    end
    
  end
  
end