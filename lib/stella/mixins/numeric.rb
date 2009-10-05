

class Numeric
  # TODO: Use 1024
  def to_bytes
    args = case self.abs.to_i
    when 0..1_000
      [(self).to_s, 'B']
    when 1_000..1_000_000
      [(self / 1000).to_s, 'KB']
    when 1_000_000..1_000_000_000
      [(self / (1000**2)).to_s, 'MB']
    when 1_000_000_000..1_000_000_000_000
      [(self / (1000**3)).to_s, 'GB']
    when 1_000_000_000_000..1_000_000_000_000_000
      [(self / (1000**4)).to_s, 'TB']
    else
      [self, 'B']
    end
    '%3.2f%s' % args
  end
end

