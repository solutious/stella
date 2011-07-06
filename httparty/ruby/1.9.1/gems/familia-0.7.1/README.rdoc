# Familia - 0.7 BETA

**Organize and store ruby objects in Redis**


## Basic Example

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
    
    
## More Information

* [Codes](http://github.com/delano/familia)
* [RDocs](http://delano.github.com/familia)


## Credits

* [Delano Mandelbaum](http://goldensword.ca)
