


module Stella::Test::Run

  class Summary < Stella::Storable
    attr_accessor :format
    
    field :availability => Float
    field :transactions => Integer
    field :elapsed_time => Float
    field :data_transferred => Float
    field :headers_transferred => Float 
    field :response_time => Float
    field :transaction_rate => Float
    field :throughput => Float
    field :vusers => Integer
    field :successful => Integer
    field :failed => Integer
    field :note => String
    field :raw => String
    field :tool => String
    field :version => String

    def initialize(note="")
      #init
      @note = note
      reset
    end
    
    def reset
      @transactions = 0
      @headers_transferred = 0
      @elapsed_time = 0
      @data_transferred = 0
      @response_time = 0
      @successful = 0
      @failed = 0
      @transaction_rate = 0
      @vusers = 0
    end
    
    def availability
      begin
        (@transactions / @successful).to_f * 100
      rescue => ex
        return 0.0
      end
    end
    
    # We calculate the throughput because Apache Bench does not provide this
    # value in the output. 
    def throughput
      begin
        return (@data_transferred / @elapsed_time).to_f
      rescue => ex
        return 0.0
      end
    end
    

    
    def available?
      @successful && @transactions && @elapsed_time && @vusers && @response_time
    end
    
  end
  
  
end