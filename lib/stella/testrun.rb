
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
    
    def initialize(hosts=[], mode=:functional, tp=nil)
      self.testplan = tp
      self.hosts = hosts
      self.status = "new"
      self.mode = mode
      self.start_at = 0
      @created = Time.now.to_f  # used to keep the generated testrun id unique
      check!
    end
    
    def check!
      @hosts &&= @hosts.collect { |uri|
        uri = 'http://' << uri unless uri.match /^https?:\/\//i
        URI.parse uri
      }
    end
  end
end




