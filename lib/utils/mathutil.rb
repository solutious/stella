

module MathUtil
  
  def self.variance(population)
    n = 0
    mean = 0.0
    s = 0.0
    population.each { |x|
      n = n + 1
      delta = (x - mean).to_f
      mean = (mean + (delta / n)).to_f
      s = (s + delta * (x - mean)).to_f
    }
    
    return s / n
  end

  # calculate the standard deviation of a population
  # accepts: an array, the population
  # returns: the standard deviation
  def self.standard_deviation(population)
    Math.sqrt(variance(population))
  end
  
  # enforce_limit
  #
  # Enforce a minimum and maximum value 
  def self.enforce_limit(val,min,max)
    val = min  if val < min
    val = max  if val > max
    val
  end
  
end




module Enumerable

    ##
    # Sum of all the elements of the Enumerable

    def sum
        return 0 if !self || self.empty?
        self.inject(0) { |acc, i| acc.to_f + i.to_f }
    end

    ##
    # Average of all the elements of the Enumerable
    #
    # The Enumerable must respond to #length

    def average
      return 0 unless self
      self.sum / self.length.to_f
    end

    ##
    # Sample variance of all the elements of the Enumerable
    #
    # The Enumerable must respond to #length

    def sample_variance
        return 0 unless self
        avg = self.average
        sum = self.sum
        return (1 / self.length.to_f * sum)
    end

    ##
    # Standard deviation of all the elements of the Enumerable
    #
    # The Enumerable must respond to #length

    def standard_deviation
      return 0 unless self
        return Math.sqrt(self.sample_variance)
    end

end