require 'ncurses'

module Term
	class Visual

		# == What's this?
		#
		# This class keeps track of colors for a Term::Visual object. You can
		# add colors one by one, through Term::Visual::Palette#setcolor or with
		# a hash, via Term::Visual::Palette#setcolors.
		#
		# When you set a color, you provide an identifier and a description.
		# The identifier can be any string you like (there are a few
		# identifiers used by Term::Visual; I'll get to that in just a bit).
		# The description is a readable way of defining console colors. For
		# example, "red on blue". It's just what it says. You can also add more
		# fancy stuff, like "bold flashing red on bright blue". Colors and
		# attributes also have shortened names. You could write "bold flashing
		# red on bright blue" as "bo fl re on br bl". Though that's somewhat
		# less readable, it's also quicker to type, and makes more sense in
		# things like "re on gr". You can mix and match the shortened versions
		# with their lengthier counterparts: "bold re on br green" is a valid
		# color description. Descriptions are case-insensitive.
		#
		# To use a color in a string (anywhere you provide Term::Visual with a
		# string it prints somewhere, it ought to use color), use
		# %(*identifier*). Example: "This is not colored. %(color)This is."
		#
		# Some color identifiers are used by Term::Visual. These are:
		#
		# [+default+] This color is used as the default color in the buffer
		#             window and in the edit window. Defaults to "default on
		#             default".
		# [+title+] This color is used for the title bar. Defaults to "white on
		#           blue".
		# [+status+] This color is used for the status bar. Defaults to "white
		#            on blue".
		# [+edit+] This color is used for the edit line, where text gets typed
		#          by the user. Defaults to "default on default".
		#
		# == Examples
		#
		# === One by one
		#
		#     vt.setcolor("line number", "bright blue on red")
		#     vt.setcolor("operator", "red on default")
		#     vt.setcolor("variable", "gr on de")
		#
		#     vt.current_window.print("%(line number)1%(default): " +
		#         "%(variable)a%(default) %(operator)=%(default) " +
		#         "2 %(operator)+%(default) 2")
		#
		# === All at once
		#
		#     vt.setcolors(
		#         'line number'	=> 'bright blue on red',
		#         'operator'	=> 'red on default',
		#         'variable'	=> 'gr on de'
		#     )
		#
		#     [...]
		#
		class Palette
			ColorTable = {
				"bk"		=> Ncurses::COLOR_BLACK,
				"black"		=> Ncurses::COLOR_BLACK,
				"bl"		=> Ncurses::COLOR_BLUE,
				"blue"		=> Ncurses::COLOR_BLUE,
				"br"		=> Ncurses::COLOR_YELLOW, # COLOR_YELLOW is brown.
				"brown"		=> Ncurses::COLOR_YELLOW,
				"fu"		=> Ncurses::COLOR_MAGENTA,
				"fuschia"	=> Ncurses::COLOR_MAGENTA,
				"ma"		=> Ncurses::COLOR_MAGENTA,
				"magenta"	=> Ncurses::COLOR_MAGENTA,
				"pu"		=> Ncurses::COLOR_MAGENTA,
				"purple"	=> Ncurses::COLOR_MAGENTA,
				"cy"		=> Ncurses::COLOR_CYAN,
				"cyan"		=> Ncurses::COLOR_CYAN,
				"gr"		=> Ncurses::COLOR_GREEN,
				"green"		=> Ncurses::COLOR_GREEN,
				"re"		=> Ncurses::COLOR_RED,
				"red"		=> Ncurses::COLOR_RED,
				"wh"		=> Ncurses::COLOR_WHITE,
				"white"		=> Ncurses::COLOR_WHITE,
				"ye"		=> Ncurses::COLOR_YELLOW,
				"yellow"	=> Ncurses::COLOR_YELLOW,
				"de"		=> -1, # default color
				"default"	=> -1,
			} # :nodoc:
			AttrTable = {
				"al"			=> Ncurses::A_ALTCHARSET,
				"alt"			=> Ncurses::A_ALTCHARSET,
				"alternate"		=> Ncurses::A_ALTCHARSET,
				"blink"			=> Ncurses::A_BLINK,
				"blinking"		=> Ncurses::A_BLINK,
				"bo"			=> Ncurses::A_BOLD,
				"bold"			=> Ncurses::A_BOLD,
				"bright"		=> Ncurses::A_BOLD,
				"dim"			=> Ncurses::A_DIM,
				"fl"			=> Ncurses::A_BLINK,
				"flash"			=> Ncurses::A_BLINK,
				"flashing"		=> Ncurses::A_BLINK,
				"hi"			=> Ncurses::A_BOLD,
				"in"			=> Ncurses::A_INVIS,
				"inverse"		=> Ncurses::A_REVERSE,
				"inverted"		=> Ncurses::A_REVERSE,
				"invisible"		=> Ncurses::A_INVIS,
				"inviso"		=> Ncurses::A_INVIS,
				"lo"			=> Ncurses::A_DIM,
				"low"			=> Ncurses::A_DIM,
				"no"			=> Ncurses::A_NORMAL,
				"norm"			=> Ncurses::A_NORMAL,
				"normal"		=> Ncurses::A_NORMAL,
				"pr"			=> Ncurses::A_PROTECT,
				"prot"			=> Ncurses::A_PROTECT,
				"protected"		=> Ncurses::A_PROTECT,
				"reverse"		=> Ncurses::A_REVERSE,
				"rv"			=> Ncurses::A_REVERSE,
				"st"			=> Ncurses::A_STANDOUT,
				"stand"			=> Ncurses::A_STANDOUT,
				"standout"		=> Ncurses::A_STANDOUT,
				"un"			=> Ncurses::A_UNDERLINE,
				"under"			=> Ncurses::A_UNDERLINE,
				"underline"		=> Ncurses::A_UNDERLINE,
				"underlined"	=> Ncurses::A_UNDERLINE,
				"underscore"	=> Ncurses::A_UNDERLINE,
			} # :nodoc:

			def initialize # :nodoc:
				@colors = Hash.new
				@curcolid = 20
			end

			def [](name) # :nodoc:
				if !name.respond_to?(:to_str)
					return false
				end
				return false if !@colors[name]
				@colors[name][1]
			end

			# This takes a hash of identifier => description pairs and calls
			# #setcolor on each of them.
			def setcolors(hash)
				if !hash.kind_of?(Hash)
					raise "Term::Visual::Palette#setcolors takes a Hash arg."
				end
				hash.each { |k, v|
					self.setcolor(k, v)
				}
			end

			# Set color identifier +name+ with description +desc+. +name+ is
			# case-sensitive (the identifier "foo" is different from "FOO" is
			# different from "fOo"), but +desc+ is case-insensitive.
			def setcolor(name, desc)
				if !desc.kind_of?(String) && !name.kind_of?(String)
					raise "Term::Visual::Palette.addcolor requires two " \
					"String arguments."
				end
				desc.strip!
				desc.downcase!
				fg, bg = desc.split(/\s+on\s+/, 2)

				fgcolor, bgcolor, attr = 0, 0, 0

				for w in fg.split(/\s+/)
					if ColorTable[w]
						fgcolor |= ColorTable[w]
					end
					if AttrTable[w]
						attr |= AttrTable[w]
					end
				end
				
				for w in bg.split(/\s+/)
					if ColorTable[w]
						bgcolor |= ColorTable[w]
					end
					if AttrTable[w]
						attr |= AttrTable[w]
					end
				end
				
				if @colors[name]
					id = @colors[name][0]
					Ncurses.init_pair(id, fgcolor, bgcolor)
					@colors[name][1] = Ncurses::COLOR_PAIR(id) | attr
				else
					Ncurses.init_pair(@curcolid, fgcolor, bgcolor)
					@colors[name] = [@curcolid, \
						Ncurses::COLOR_PAIR(@curcolid) | attr]
					@curcolid += 1
				end
			end
			alias_method :[]=, :setcolor
		end
	end
end
