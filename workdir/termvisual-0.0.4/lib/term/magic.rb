require 'stringio'

module Term
  class Magic

  def initialize

    @cursor=Term::Magic::Cursor.new
    @font=Term::Magic::Font.new
    @device=Term::Magic::Device.new
    @erase=Term::Magic::Erase.new

    @testvar="OK\n"
  end

  class Value
    def initialize
      @string=""
    end

    class Cursor
      def self.initstr
        @string=""
      end
      def self.up(count)
        self.initstr
        @string.concat("\x1b[")
        @string.concat(count.to_s)
        @string.concat("A")
        return @string
      end
      def self.down(count)
        self.initstr
        @string.concat("\x1b[")
        @string.concat(count.to_s)
        @string.concat("B")
        return @string
      end
      def self.fwd(count)
        self.initstr
        @string.concat("\x1b[")
        @string.concat(count.to_s)
        @string.concat("C")
        return @string
      end
      def self.bwd(count)
        self.initstr
        @string.concat("\x1b[")
        @string.concat(count.to_s)
        @string.concat("D")
        return @string
      end
      def self.saveattr
        self.initstr()
        return "\x1b7"
      end
      def self.restoreattr
        self.initstr
        return "\x1b8"
      end
      def self.newline
        self.initstr
        return "\x1bE"
      end
      def self.setpos(row,column)
        self.initstr
        @string.concat("\x1b[")
        @string.concat(row.to_s)
        @string.concat(";")
        @string.concat(column.to_s)
        @string.concat("H")
        return @string
      end
      def self.getpos
        return "\x1b[6n"
      end
      def self.next
        return "\x1bM"
      end
      def self.prev
        return "\x1bD"
      end
      def self.setg0(charset)
        case charset
          when "UK"
            return "\x1b(A"
          when "USASCII"
            return "\x1b(B"
          when "SPECIAL"
            return "\x1b(0"
          when "ROM"
            return "\x1b(1"
          when "ROMSPECIAL"
            return "\x1b(2"
          else
            return nil
        end
      end
      def self.setg1(charset)
        case charset
          when "UK"
            return "\x1b)A"
          when "USASCII"
            return "\x1b)B"
          when "SPECIAL"
            return "\x1b)0"
          when "ROM"
            return "\x1b)1"
          when "ROMSPECIAL"
            return "\x1b)2"
          else
            return nil
        end
      end

      def self.useg0
        return "\x0f"
      end
      def self.useg1
        return "\x0e"
      end

      

    end

    class Font
      def initialize
        @string=""
        @first=true
      end
      def self.set(attr)
        @string=""
        @first=true
        @string.concat("\x1b[")
        if attr=="" then
          return "\x1b[0m"
        end
        if attr["bold"]==true then
          if @first==true then @first=false end
          @string.concat("1")
        end
        if attr["underline"]==true then
          if @first==true then @first=false else @string.concat(";") end
          @string.concat("4")
        end
        if attr["blink"]==true then
          if @first==true then @first=false else @string.concat(";") end
          @string.concat("5")
        end
        if attr["rev"]==true then
          if @first==true then @first=false else @string.concat(";") end
          @string.concat("7")
        end

        case attr["bg"]
        when "red"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("41")
          end
        when "green"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("42")
          end
        when "yellow"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("43")
          end
        when "blue"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("44")
          end
        when "magenta"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("45")
          end
        when "cyan"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("46")
          end
        when "white"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("47")
          end
        end

        case attr["fg"]
        when "red"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("31")
          end
        when "green"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("32")
          end
        when "yellow"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("33")
          end
        when "blue"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("34")
          end
        when "magenta"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("35")
          end
        when "cyan"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("36")
          end
        when "white"
          begin
            if @first==true then @first=false else @string.concat(";") end
            @string.concat("37")
          end
        end

        @string.concat("m")
        return @string
      end

    end

    class Device
      def self.reset
        return "\x1bc"
      end
      def self.area(top,bottom)
        @@string=""
        @@string.concat("\x1b[")
        @@string.concat(top.to_s)
        @@string.concat(";")
        @@string.concat(bottom.to_s)
        @@string.concat("r")
        return @@string
      end
      def self.reverse(param)
        if param==true then
          return "\x1b[?5h"
        end
        if param==false then
          return "\x1b[?5l"
        end
      end
    end

    class Erase
      def self.eol
        return "\e[K"
      end
      def self.bol
        return "\e[1K"
      end
      def self.l
        return "\e[2K"
      end
      def self.eos
        return "\e[J"
      end
      def self.bos
        return "\e[1J"
      end
      def self.s
        return "\e[2J"
      end
    end

  end

  class Cursor
    def initialize
      @Cvalue=Value::Cursor
    end
    def up(count)
      print @Cvalue.up(count)
      STDOUT.flush
    end
    def down(count)
      print @Cvalue.down(count)
      STDOUT.flush
    end
    def fwd(count)
      print @Cvalue.fwd(count)
      STDOUT.flush
    end
    def bwd(count)
      print @Cvalue.bwd(count)
      STDOUT.flush
    end
    def saveattr
      print @Cvalue.saveattr
      STDOUT.flush
    end
    def restoreattr
      print @Cvalue.restoreattr
      STDOUT.flush
    end
    def newline
      print @Cvalue.newline
      STDOUT.flush
    end
    def setpos(row,column)
      print @Cvalue.setpos(row,column)
      STDOUT.flush
    end
    def getpos
      val =  @Cvalue.getpos
      print val
      STDOUT.flush
    end
    def next
      print @Cvalue.next
      STDOUT.flush
    end
    def prev
      print @Cvalue.prev
      STDOUT.flush
    end
    def setg0(charset)
      print @Cvalue.setg0(charset)
      STDOUT.flush
    end
    def setg1(charset)
      print @Cvalue.setg1(charset)
      STDOUT.flush
    end
    def useg0
      print @Cvalue.useg0
      STDOUT.flush
    end
    def useg1
      print @Cvalue.useg1
      STDOUT.flush
    end
  end

  class Font
    def initialize
      @Fvalue=Value::Font
    end
    def set(attr)
      print @Fvalue.set(attr)
      STDOUT.flush
    end
  end

  class Device
    def initialize
      @Dvalue=Value::Device
    end
    def reset
      #print @dvalue.reset
      print @Dvalue.reset
      STDOUT.flush
    end
    def reverse(param)
      print @Dvalue.reverse(param)
      STDOUT.flush
    end
  end

  class Erase
    def initialize
      @Evalue=Value::Erase
    end
    def bol
      print @Evalue.bol
    end
    def eol
      print @Evalue.eol
    end
    def l
      print @Evalue.l
    end
    def bos
      print @Evalue.bos
    end
    def eos
      print @Evalue.eos
    end
    def s
      print @Evalue.s
    end
  end

  attr_accessor(:cursor,:testvar,:font,:device,:erase)

end
end
