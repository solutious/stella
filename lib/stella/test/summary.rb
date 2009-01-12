
require 'stella/test/base'

module Stella::Test
  
  # Stella::Test::Summary
  class Summary < Stella::Storable
    include Base
    
    attr_reader :runs
    
    def initialize(msg="")
      @message = msg
      @runs = []
    end
    
    # Add a TestRun object to the list
    def add_run(run)
      raise "I got a #{run.class} but I wanted a Run::Summary" unless run.is_a?(Run::Summary)
      @runs << run
      calculate
    end
    
    private 
    def calculate
      # We simply keep a running tally of these
      @transactions_total = 0
      @headers_transferred_total = 0
      @data_transferred_total = 0
      @elapsed_time_total = 0
      @successful_total = 0
      @failed_total = 0
      
      # We keep a list of the values for averaging and std dev
      elapsed_times = []
      transaction_rates = []
      vusers_list = []
      response_times = []
      response_time = []
      transaction_rate = []
      throughput = []
      vusers = []
      
      # Each run is the summary of a single run (i.e. run01/SUMMARY.csv)
      runs.each do |run|
        # These are totaled
        @transactions_total += run.transactions || 0
        @headers_transferred_total += run.headers_transferred || 0
        @data_transferred_total += run.data_transferred || 0
        @successful_total += run.successful || 0
        @failed_total += run.failed || 0
        @elapsed_time_total += run.elapsed_time || 0
        
        # These are used for standard deviation
        elapsed_times << run.elapsed_time
        transaction_rates << run.transaction_rate
        vusers_list << run.vusers
        response_times << run.response_time
        throughput << run.throughput
        response_time << run.response_time
        transaction_rate << run.transaction_rate
        vusers << run.vusers
      end
      
      # Calculate Averages
      @elapsed_time_avg = elapsed_times.average
      @throughput_avg = throughput.average
      @response_time_avg = response_time.average
      @transaction_rate_avg = transaction_rate.average
      @vusers_avg = vusers.average 
      
      # Calculate Standard Deviations
      @elapsed_time_sdev = elapsed_times.standard_deviation
      @throughput_sdev= throughput.standard_deviation
      @transaction_rate_sdev = transaction_rates.standard_deviation
      @vusers_sdev = vusers_list.standard_deviation
      @response_time_sdev = response_times.standard_deviation
      
    end
  end
  
end