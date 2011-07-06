require 'storable'

class Bone < Storable
  include Familia
  index [:token, :name]
  field :token
  field :name
  list   :owners
  set    :tags
  zset   :metrics
  hash   :props
  string :value, :default => "GREAT!"
end

class Session < Storable
  include Familia
  index :sessid
  field :sessid
  field :custid
  include Familia::Stamps
  ttl 60 # seconds to live
end

class Customer < Storable
  include Familia
  index :custid
  field :custid => Symbol
  field :name
  include Familia::Stamps
  # string :object, :class => self  # example of manual override
  class_list :customers, :suffix => []
  class_string :message
end

class Limiter < Storable
  include Familia
  index :name
  field :name
  string :counter, :quantize => true, :ttl => 1.hour, :quantize => [10.minutes, '%H:%M', 1302468980]
end