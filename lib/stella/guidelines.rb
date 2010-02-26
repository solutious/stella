

module Stella
  module Guidelines
    extend self
    AFE = "Always fail early"
    AII = "Accurate is important"
    CBC = "Consistency before cuteness"
    DBD = "Don't be defensive"
    def inspect
      all = Stella::Guidelines.constants
      g = all.collect { |c| '%s="%s"' % [c, const_get(c)] }
      %q{#<Stella::Guidelines:0x%s %s>} % [self.object_id, g.join(' ')]
    end
  end
end

p Stella::Guidelines if __FILE__ == $0