# A port of Text::Graph, which generates pretty ascii bar graphs from
# numeric datasets, like
# 
#     aaaa :       (1)
#       bb :..*    (22)
#      ccc :...*   (43)
#   dddddd :.....* (500)
#       ee :......*(1000)
#        f :.....* (300)
#      ghi :...*   (50)
# 
# It accepts data in the following forms (see the 'extract' method):
# 
# # { label => value, label => value, ... }
# # { :values => { label => value, ...} }
# # { :values => [values] }
# # {:values => { label => value, label => value }, :labels => [...]}
# # {:values => [values], :labels => [labels]}
# # [ [label, value], [label, value], ...]
# # [[values], [labels]]
# 
# Numeric parameters:
# :minval
# :maxval
# :maxlen
# 
# Boolean parameters:
# :log   # logarithmic scale
# :right # label justification
# 
# Display parameters:
# :marker
# :fill
# :separator
# :style # {:bar|:line} - sets default values for marker and fill
# :showval # numeric value after bar

# Text::Graph
# Port of Wade Johnson's Text::Graph for perl
#   http://search.cpan.org/src/GWADEJ/Text-Graph-0.23/Graph.pm
#  
# Author: Martin DeMello <martindeme...@gmail.com>

module Enumerable
  def minmax
    min = 1.0/0
    max = -1.0/0
    each {|i|
      min = i if i < min
      max = i if i > max
    }
    [min, max]
  end

  def map_with_index
    a = []
    each_with_index {|e, i| a << yield(e,i)}
    a
  end
end

class TextGraph
  include Math

  def initialize(data, params = {})
    @data = extract(data)
    @params = {:style => (params[:style] || :bar)}
    apply_style(@params[:style])
    @params.update(params)
    @params[:separator] ||= " :"
  end

  def update_params(par)
    apply_style(par[:style]) if par[:style]
    @params.update(par)
  end

  def apply_style(style)
    if style == :bar
      @params[:marker] = "*"
      @params[:fill] = "*"
    elsif style == :line
      @params[:marker] = '*'
      @params[:fill] = ' '
    else
      raise "Invalid style #{style}"
    end
  end

  def extract(data)
    if data.is_a? Array
      if data.length == 2 and data[0].is_a? Array and data[1].is_a? Array
  # [[values], [labels]]
  a = {}
  a[:values] = data[0]
  a[:labels] = data[1]
  data = a
      else
  # [ [label, value], [label, value], ...]
  a = {:values => [], :labels => []}
  data.each {|i,j| a[:labels] << i; a[:values] << j}
      end
    end

    if (data.length == 2) and data[:values] and data[:labels]
      if data[:values].is_a? Array
  # {:values => [values], :labels => [labels]}
  # do nothing
      elsif data[:values].is_a? Hash
  # {:values => { label => value, label => value }, :labels => [...]}
  a = data[:labels].map {|i| data[:values][i]}
  data[:values] = a
      else
  raise "Invalid valueset"
      end
    elsif (data.length == 1) and data[:values]
      if data[:values].is_a? Array
  # { :values => [values] }
  data[:labels] = data[:values].map {""}
      elsif data[:values].is_a? Hash
  # { :values => { label => value, ...} }
  data[:labels] = data[:values].keys.sort_by {|i| i.to_s}
  data[:values] = data[:labels].map {|i| data[:values][i]}
      else
  raise "Invalid valueset"
      end
    else
      # { label => value, label => value, ... }
      a = {}
      a[:labels] = data.keys.sort_by {|i| i.to_s}
      a[:values] = a[:labels].map {|i| data[i]}
      data = a
    end
    data[:labels].map! {|i| i.to_s}
    data
  end

  def make_within(val, min, max)
    (val < min) ? min : (val > max ? max : val)
  end

  def makebar(val, m, f)
    val = (val + 0.5).to_i
    (val > 0) ? (f*(val - 1) + m) : ""
  end

  def fmt_labels (right, labels)
    len = labels.map {|i| i.length}.max
    just = right ? :rjust : :ljust
    labels.map {|i| i.send(just, len)}
  end

  def make_labelled_lines(data)
    labels = fmt_labels(@params[:right], data[:labels])
    lines  = histogram(data)
    lines.zip(labels).map {|line, label| label + @params[:separator] + line}
  end

  def histogram(data)
    values = data[:values].dup
    minval, maxval, maxlen =
      @params[:minval], @params[:maxval], @params[:maxlen]

    if @params[:log]
      values.map! {|i| log(i)}
      minval = log(minval) rescue 1 if minval
      maxval = log(maxval) rescue 1 if maxval
    end

    min, max = values.minmax
    minval ||= min
    maxval ||= max
    maxl = maxval - minval + 1
    maxlen ||= maxl
    scale = maxlen*1.0/maxl
    values = values.map {|i|
      j = make_within(i, minval, maxval) - minval
      makebar(j*scale, @params[:marker], @params[:fill])
    }

    if(@params[:showval])
      values = values.map_with_index {|v, i|
  v.ljust(maxlen) + "(#{data[:values][i]})"
      }
    end

    values
  end

  def to_s
    make_labelled_lines(@data).join("\n") + "\n"
  end
end

if __FILE__ == $0

  a = TextGraph.new({
    :values => [100,142,43,54,111,62,52],
    :labels => %w(aaaa bb ccc dddddd ee f ghi)
  })

  puts a

  #  aaaa   :
  #  bb     :*
  #  ccc    :***
  #  dddddd :****
  #  ee     :*********
  #  f      :**
  #  ghi    :****

  puts "-------------------------------------------------------------"

  a.update_params(:style => :line, :right => true, :showval => true)
  puts a

  #    aaaa :          (1)
  #      bb :*         (2)
  #     ccc :  *       (4)
  #  dddddd :   *      (5)
  #      ee :        * (10)
  #       f : *        (3)
  #     ghi :   *      (5)

  puts "-------------------------------------------------------------"

  b = TextGraph.new({ :a=>1, :b=>5, :c=>20, :d=>10, :e=>17 }, {:maxlen => 10})
  puts b

  #  a :
  #  b :**
  #  c :**********
  #  d :*****
  #  e :********

  puts "-------------------------------------------------------------"

  c = TextGraph.new({:values => { :a=>1, :b=>5, :c=>20, :d=>10, :e=>17 },
        :labels => [:a, :c, :d]},
        {:minval => 0, :maxval => 15, :showval => true})
  puts c

  #  a :*               (1)
  #  c :*************** (20)
  #  d :**********      (10)

  puts "-------------------------------------------------------------"

  d = TextGraph.new([[10,22,43,500,1000,300,50], %w(aaaa bb ccc dddddd ee f ghi)],
        { :style => :line,
          :right => true,     # right-justify labels
          :fill => '.',       # change fill-marker
          :log => false,       # logarithmic graph
          :showval => true    # show actual values
  }
       )
       puts d

       #    aaaa :       (1)
       #      bb :..*    (22)
       #     ccc :...*   (43)
       #  dddddd :.....* (500)
       #      ee :......*(1000)
       #       f :.....* (300)
       #     ghi :...*   (50)

end