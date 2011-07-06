autoload :Console, 'drydock/console'
class String
  @@print_with_attributes = true
  def String.disable_colour; @@print_with_attributes = false; end
  def String.disable_color;  @@print_with_attributes = false; end
  def String.enable_colour;  @@print_with_attributes = true;  end
  def String.enable_color;   @@print_with_attributes = true;  end
  
  # +col+, +bgcol+, and +attribute+ are symbols corresponding
  # to Console::COLOURS, Console::BGCOLOURS, and Console::ATTRIBUTES.
  # Returns the string in the format attributes + string + defaults.
  #
  #     "MONKEY_JUNK".colour(:blue, :white, :blink)  # => "\e[34;47;5mMONKEY_JUNK\e[39;49;0m"
  #
  def colour(col, bgcol = nil, attribute = nil)
    return self unless @@print_with_attributes
    Console.style(col, bgcol, attribute) +
    self +
    Console.style(:default, :default, :default)
  end
  alias :color :colour
  
  # See colour
  def bgcolour(bgcol = :default)
    return self unless @@print_with_attributes
    Console.style(nil, bgcol, nil) +
    self +
    Console.style(nil, :default, nil)
  end
  alias :bgcolor :bgcolour
  
  # See colour
  def att(a = :default)
    return self unless @@print_with_attributes
    Console.style(nil, nil, a) +
    self +
    Console.style(nil, nil, :default)
  end
  
  # Shortcut for att(:bright)
  def bright; att(:bright); end
  
  # Print the string at +x+ +y+. When +minus+ is any true value
  # the length of the string is subtracted from the value of x
  # before printing. 
  def print_at(x=nil, y=nil, minus=false)
    args = {:minus=>minus}
    args[:x] &&= x
    args[:y] &&= y
    Console.print_at(self, args)
  end
  
  # Returns the string with ANSI escape codes removed.
  #
  # NOTE: The non-printable attributes count towards the string size. 
  # You can use this method to get the "visible" size:
  #
  #     "\e[34;47;5mMONKEY_JUNK\e[39;49;0m".noatt.size      # => 11
  #     "\e[34;47;5mMONKEY_JUNK\e[39;49;0m".size            # => 31
  #
  def noatt
    gsub(/\e\[?[0-9;]*[mc]?/, '')
  end
  alias :noansi :noatt
  
end
