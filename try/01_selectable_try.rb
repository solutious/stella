require 'selectable'

## Can tag Strings
a = TaggableString.new("stella")
a.add_tags :type => :metric, :title => "Metric"
a.tag_values
#=> [:metric, "Metric"]

## Can filter Array with full tags
a = SelectableArray.new
a << TaggableString.new("stella1", :type => :metric)
a << TaggableString.new("stella2", :type => :metric)
a << TaggableString.new("stella3", :type => :log)
a.filter(:type => :metric)
#=> ["stella1", "stella2"]

## Can filter Array with just values
a = SelectableArray.new
a << TaggableString.new("stella1", :type => :metric)
a << TaggableString.new("stella2", :type => :metric)
a << TaggableString.new("stella3", :type => :log)
a.filter(:metric)
#=> ["stella1", "stella2"]


