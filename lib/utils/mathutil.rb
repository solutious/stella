

module MathUtil
  
  # enforce_limit
  #
  # Enforce a minimum and maximum value 
  def self.enforce_limit(val,min,max)
    val = min  if val < min
    val = max  if val > max
    val
  end
  
end

