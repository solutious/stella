

class Numeric
  include Time::Units
  # TODO: Use 1024?
  def to_bytes
    args = case self.abs.to_i
    when 0..1000
      [(self).to_s, 'B']
    when (1000)..(1000**2)
      [(self / 1000.to_f).to_s, 'KB']
    when (1000**2)..(1000**3)
      [(self / (1000**2).to_f).to_s, 'MB']
    when (1000**3)..(1000**4)
      [(self / (1000**3).to_f).to_s, 'GB']
    when (1000**4)..(1000**6)
      [(self / (1000**4).to_f).to_s, 'TB']
    else
      [self, 'B']
    end
    '%3.2f%s' % args
  end
end

