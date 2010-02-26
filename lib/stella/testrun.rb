
module Stella
  class Testrun < Storable
    include Gibbler::Complex
    
    field :testplan
    field :hosts        => Array
    
    field :mode          # (f)unctional or (l)oad
    field :desc
    field :clients      => Integer
    field :duration     => Integer
    field :repetitions  => Integer
    field :arrival      => Float
    
    field :nowait
    field :status
    field :start_at     => Integer
    
    def initialize(tp, hosts=[], mode=:functional)
      self.testplan = tp
      self.hosts = hosts
      self.status = "new"
      self.mode = mode
      self.start_at = 0
      @created = Time.now.to_f  # used to keep the generated testrun id unique
    end
  end
end




