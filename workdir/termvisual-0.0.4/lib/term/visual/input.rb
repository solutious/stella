# vim: set noet :
require 'ncurses'
require 'observer'

module Term
	class Visual
		class Input # :nodoc: all
			include Observable
			attr_reader :data, :cursor

			def initialize(window, hash=Hash.new)
				@window = window
				if !hash.kind_of?(Hash)
					raise "Term::Visual::Input.new requires a Hash argument"
				end
				@history_pos = -1
				@history_size = hash["historysize"] || 50
				@history = Array.new
				@data = String.new
				@cursor = 0
				@tabcomplete = hash["tabcomplete"] || nil
				@insert = true
				@bindings = Hash.new
				if hash['observers'].kind_of?(Array)
					hash['observers'].each { |observer|
						if observer.kind_of?(Array)
							self.add_observer observer[0],
										  observer[1] ? observer[1] : :update
						else
							self.add_observer observer
						end
					}
				end
			end

			def bind(key, block)
				esc = ''
				while key.sub!(/^(A(?:lt)?|C(?:trl)?)-/i, '')
					mod = $1.upcase
					if mod =~ /^C/
						esc += '^'
					elsif mod =~ /^A/
						esc += '^['
					else
						raise 'Impossible error.'
					end
				end
				if key.length == 1
					key = esc + key
				else
					key = esc + "KEY_" + key.upcase
				end
				@bindings[key] = block
			end

			def on_stdin
				while ch = Ncurses.getch
					return if ch == Ncurses::ERR
					handlechar ch
				end
			end
					
			def handlechar ch
				k = Ncurses::keyname(ch).upcase
				k = Ncurses::unctrl(k).upcase if k < " " or k > "~"
				ret = nil
				
				# save if it's a meta key
				if k == '^['
					@meta = k
					return
				end
				# retrieve saved meta key, if any
				if @meta
					k = @meta + k
					@meta = nil
				end
				
				if @bindings[k]
					@bindings[k].call(ch)
					return
				end

				case k
				when 'KEY_ENTER', '^M'
					@history.push(@data.dup)
					@data = ""
					@cursor = 0
					ret = @history[-1]
					changed
					notify_observers :line, ret
				when 'KEY_BACKSPACE', '^H', '^?'
					if @cursor > 0
						@cursor -= 1
						@data[@cursor] = ''
					end
				when 'KEY_DC', '^D'
					@data[@cursor] = "" if @cursor < @data.length
				when 'KEY_LEFT'
					@cursor -= 1 if @cursor > 0
				when 'KEY_RIGHT', '^F'
					@cursor += 1 if @cursor < @data.length
				when 'KEY_END', 'KEY_LL', '^E'
					@cursor = @data.length
				when 'KEY_HOME', '^A'
					@cursor = 0
				when 'KEY_PPAGE'
					self.window.scroll(-self.window.buf_height/2)
				when 'KEY_NPAGE'
					self.window.scroll(self.window.buf_height/2+1)
				when 'KEY_RESIZE', '^L'
					self.window.resize
				else
					@history_pos = -1
					@data.insert(@cursor, Ncurses::keyname(ch))
					@cursor += 1
				end
				self.window.refresh_edit
				Ncurses.doupdate
			end

			protected
			def window
				@window
			end
		end
		class CommonInput < Input # :nodoc: all
			protected
			def window
				@window.current_window
			end
		end
	end
end
