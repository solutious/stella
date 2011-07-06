class Object 

  # Executes tput +capnam+ with +args+. Returns true if tcap gives
  # 0 exit status and false otherwise. 
  # 
  #     tput :cup, 1, 4
  #     $ tput cup 1 4
  #
  def tput(capnam, *args)
    system("tput #{capnam} #{args.flatten.join(' ')}")
  end
  
  # Executes tput +capnam+ with +args+. Returns the output of tput.
  # 
  #     tput_val :cols  # => 16
  #     $ tput cols     # => 16
  #
  def tput_val(capnam, *args)
    `tput #{capnam} #{args.flatten.join(' ')}`.chomp
  end
end


