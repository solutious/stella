
module Stella
  class Testrun < Storable
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
    
    def initialize(tp, hosts=[])
      self.testplan = tp, self.hosts = hosts
      self.status = "new"
      self.mode = :functional
      self.start_at = 0
    end
  end
end




