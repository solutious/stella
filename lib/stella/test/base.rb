
module Stella::Test
  
  module Base
    
    attr_reader :message
    attr_reader :elapsed_time_avg, :transaction_rate_avg, :vusers_avg, :response_time_avg
    attr_reader :elapsed_time_sdev, :transaction_rate_sdev, :vusers_sdev, :response_time_sdev
    attr_accessor :transactions_total, :headers_transferred_total, :data_transferred_total
    attr_accessor :successful_total, :failed_total, :elapsed_time_total, :throughput_avg, :throughput_sdev
    
    def availability
      return 0 if @successful_total == 0
      begin
        (@transactions_total / @successful_total).to_f * 100
      rescue => ex
        0.0
      end
    end
    
    
    # Defines the fields the are output by to_hash and to_csv. 
    # For to_csv, this also determines the field order
    def field_names
      [ 
        :message,
        :elapsed_time_avg,  :transaction_rate_avg,  :vusers_avg,  :response_time_avg,
        :elapsed_time_sdev, :transaction_rate_sdev, :vusers_sdev, :response_time_sdev,
        
        :transactions_total, :successful_total, :failed_total,
        :data_transferred_total, :headers_transferred_total,
        
        :elapsed_time_total, :availability, :throughput_avg, :throughput_sdev
      ]
    end
    
    def field_types
      # Dave, this is silly! 
      [
        String,
        Float, Float, Float, Float, 
        Float, Float, Float, Float, 
        Float, Float, Float, 
        Float, Float, 
        Float, Float, Float, Float
      ]
    end
  end
end