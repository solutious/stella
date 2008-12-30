# vim: set noet :
require 'ncurses'
require 'observer'
require 'eventmanager'

Thread.abort_on_exception = true

module Term # :nodoc:
	class Visual
		attr_reader :palette, :current_window, :common_input, :global_prefix
		
		def on_winch
			# thanks to http://halffull.org/files/span
			Ncurses.def_prog_mode
			Ncurses.endwin
			Ncurses.reset_prog_mode

			resize
			@common_input.on_stdin # KEY_RESIZE needs to be read for some reason
		end
		
		# Creates a new Term::Visual object.
		def initialize
			Ncurses.initscr
			at_exit { Ncurses.endwin if Ncurses.respond_to?(:endwin) }

			Ncurses.cbreak
			Ncurses.noecho
			Ncurses.nodelay Ncurses.stdscr, true
			# This was here before; bd_ added the above line. I'm confused.
			# Ncurses.stdscr.nodelay(true)
			Ncurses.nonl
			Ncurses.start_color
			Ncurses.use_default_colors
			Ncurses.stdscr.intrflush(false)
			Ncurses.stdscr.keypad(true)

			@windows = Array.new
			@line = String.new

			@palette = Term::Visual::Palette.new

			@palette.setcolors(
				'default'	=> "default on default",
				'title'		=> "white on blue",
				'status'	=> "white on blue",
				'edit'		=> "default on default"
			)

			@on_line = lambda { |line| }

			@common_input = Term::Visual::CommonInput.new(self)
			@global_prefix = ""

			trap('WINCH') { EventManager.instance.yield method(:on_winch) }
			EventManager.instance.watchread $stdin, lambda { @common_input.on_stdin }
		end

		# Update the terminal size for the current window
		# This method must be called whenever the terminal size changes.
		def resize force=false
			@current_window.resize force
		end
		
		def on_got_line block=nil, &other_kind_block
			if block.respond_to? :call
				@on_line = block
			elsif other_kind_block
				@on_line = other_kind_block
			end
		end

		# Sets the global prefix. +prefix+ may be a String object or a block
		# (or anything that responds to +call+). If +prefix+ is a block (or
		# responds to +call+), then it will be called every time a line is
		# printed to the window. Strings will simply be added to the front of
		# the prefix as they are.
		def global_prefix=(prefix)
			if prefix.kind_of?(String) || prefix.respond_to?(:call)
				@global_prefix = prefix
			else
				raise "global prefix must be a String or respond to .call"
			end
		end
		
		# Create a new window.
		#
		# [+name+] identifier of the window
		# [+hash+] passed straight to Term::Visual::Window#new
		def create_window(hash=Hash.new)
			if !hash.kind_of?(Hash)
				raise "Window options must be given in a Hash."
			end
			hash["input"] = nil
			hash["global_prefix"] = @global_prefix
			window = Term::Visual::Window.new(self, hash)
			if !window
				raise "Failed to create window."
			end
			@windows.push(window)
			@current_window = window
			window.doupdate
			return window
		end

		def delete_window(window)
			if @current_window == window
				newwin = @windows.index(window) - 1
				if newwin < 0 then newwin = 0 end
				self.switch_window(@windows[newwin])
			end
			@windows.delete window
			@current_window.doupdate
			@current_window
		end

		def switch_window(window)
			if !window.kind_of?(Term::Visual::Window)
				raise ArgumentError, 'bad arg to switch_window'
			end
			if window == @current_window
				return false
			end
			@current_window = window
			window.resize true
			window.doupdate
			true
		end

		# Returns a line from the user. This function is blocking, and will
		# wait until the user presses enter before returning any text.
		#def getline
		#	@current_window.getline
		#end

		def on_line line
			if @on_line.respond_to? :call
				@on_line.call line
			end
		end

		def bind(key, block)
			@common_input.bind(key, block)
		end
	end
end

require 'term/visual/input'
require 'term/visual/palette'
require 'term/visual/window'
