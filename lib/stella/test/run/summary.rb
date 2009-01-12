


module Stella::Test::Run

  class Summary < Stella::Storable
    
    attr_accessor :note
    attr_accessor :tool, :version
    attr_accessor :test, :transactions, :headers_transferred
    attr_accessor :elapsed_time, :data_transferred, :response_time
    attr_accessor :successful, :failed, :transaction_rate, :vusers, :raw
    
    def initialize(note="")
      @note = note
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
    
    def field_names
      [
        :availability, :transactions, :elapsed_time, :data_transferred,
        :headers_transferred, :response_time, :transaction_rate, :throughput,
        :vusers, :successful, :failed, :note
      ]
    end
    def field_types
      [ 
        Float, Integer, Float, Float,
        Float,  Float,  Float, Float, 
        Integer, Integer, Integer, String
      ]
    end
    
    def available?
      @successful && @transactions && @elapsed_time && @vusers && @response_time
    end
    
  end
  
  
end