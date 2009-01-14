

module Stella::Test
  
  # Stella::Test::Stats
  class Stats < Stella::Storable

    field :elapsed_time_avg => Float
    field :transaction_rate_avg => Float
    field :vusers_avg => Float
    field :response_time_avg => Float

    field :elapsed_time_sdev => Float
    field :transaction_rate_sdev => Float
    field :vusers_sdev => Float
    field :response_time_sdev => Float


    field :transactions_total => Float
    field :successful_total => Float
    field :failed_total => Float

    field :data_transferred_total => Float
    field :headers_transferred_total => Float


    field :elapsed_time_total => Float
    field :availability => Float
    field :throughput_avg => Float
    field :throughput_sdev => Float
    
    def availability
      return 0 if @successful_total == 0
      begin
        (@transactions_total / @successful_total).to_f * 100
      rescue => ex
        0.0
      end
    end
    
    
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
      elapsed_times = ::Stats.new
      transaction_rates = ::Stats.new
      vusers_list = ::Stats.new
      response_times = ::Stats.new
      response_time = ::Stats.new
      transaction_rate = ::Stats.new
      throughput = ::Stats.new
      vusers = ::Stats.new
      
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
        elapsed_times.sample(run.elapsed_time)
        transaction_rates.sample(run.transaction_rate)
        vusers_list.sample(run.vusers)
        response_times.sample(run.response_time)
        throughput.sample(run.throughput)
        response_time.sample(run.response_time)
        transaction_rate.sample(run.transaction_rate)
        vusers.sample(run.vusers)
      end
      
      # Calculate Averages
      @elapsed_time_avg = elapsed_times.mean
      @throughput_avg = throughput.mean
      @response_time_avg = response_time.mean
      @transaction_rate_avg = transaction_rate.mean
      @vusers_avg = vusers.mean 
      
      # Calculate Standard Deviations
      @elapsed_time_sdev = elapsed_times.sd
      @throughput_sdev= throughput.sd
      @transaction_rate_sdev = transaction_rates.sd
      @vusers_sdev = vusers_list.sd
      @response_time_sdev = response_times.sd
      
    end
  end
  
end