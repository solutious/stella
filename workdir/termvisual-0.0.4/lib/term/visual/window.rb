# vim: set noet :
require 'ncurses'
require 'thread'
require 'strscan'

class String
	def tokenize &block
		s = StringScanner.new(self)
		toks = []
		while !s.eos?
			if s.scan(/(^|.+?)(|[^%])%\((.+?)\)/)
				before = (s[1] ? s[1] : '') + (s[2] ? s[2] : '')
				tag = s[3]
				toks << [:text, before] unless before.empty?
				toks << [:tag, tag]
			else
				toks << [:text, s.scan_until(/$/)]
			end
		end
		if block.respond_to?(:call)
			toks.each { |t| block.call t }
		else
			return toks
		end
	end
end

module Term
	class Visual
		class Window
			attr_reader :title, :status
			def title=(str)
				if str.respond_to?(:to_str) and str != @title
					@title = str
					refresh_title
					refresh_edit
					Ncurses.doupdate
				end
			end
			def status=(str)
				if str.respond_to?(:to_str) and str != @status
					@status = str
					refresh_status
					refresh_edit
					Ncurses.doupdate
				end
			end
			
			def setup_status
				if @usestatus
					if @status_win
						@status_win.erase
						@status_win.noutrefresh
						@status_win.delwin
					end
					@status_win =
						Ncurses.newwin(@statuslines, Ncurses.COLS,
						Ncurses.LINES - @statuslines - 1, 0)
					@status_win.erase
					@status_win.leaveok(true)
					@status_win.noutrefresh
				end
			end

			def setup_edit
				if @edit_win
					@edit_win.erase
					@edit_win.noutrefresh
					@edit_win.delwin
				end
				@edit_win = Ncurses.newwin(@editlines, Ncurses.COLS,
					Ncurses.LINES - @editlines, 0)
				@edit_win.nodelay(true)
				@edit_win.erase
				@edit_win.noutrefresh
			end

			def setup_title
				if !@usetitle
					return
				end
				if @title_win
					@title_win.erase
					@title_win.noutrefresh
					@title_win.delwin
				end
				@title_win =
					Ncurses.newwin(@titlelines, Ncurses.COLS, 0, 0)
				@title_win.erase
				@title_win.noutrefresh
			end

			def setup_buffer
				if @buffer_win
					@buffer_win.erase
					@buffer_win.noutrefresh
					@buffer_win.delwin
				end
				buf_start = @titlelines
				@buffer_win = Ncurses.newwin(self.buf_height, Ncurses.COLS,
					buf_start, 0)
				@buffer_win.erase
				@buffer_win.noutrefresh
			end

			def initialize(parent, hash)
				@parent = parent

				@bufsize = hash["bufsize"] || 500
				
				@title = hash["title"] || ""
				@usetitle = hash["usetitle"] || true
				@titlelines = hash["titlelines"] || 1
				
				@status = hash["status"] || ""
				@usestatus = hash["usestatus"] || true
				@statuslines = hash["statuslines"] || 1
				
				@input = hash["input"] || @parent.common_input
				@input.add_observer self
				@editlines = hash["editlines"] || 1

				@global_prefix = hash["global_prefix"] || ""

				@buffer = Array.new
				@buflines = Array.new
				@scroll = 0

				@inlines = Queue.new

				resize
				
				#                setup_title
				#                setup_status
				#                setup_buffer
				#                setup_edit
			  

				Ncurses.getch # weird, but this seems to fix the no-draw bug
				self.doupdate
			end

			def update type, *args
				if self == @parent.current_window and type == :line
					@parent.on_line args[0]
				end
			end

			def scroll(numlines)
				@scroll -= numlines
				if @scroll > @buffer.length - self.buf_height
					@scroll = @buffer.length - self.buf_height
				end
				if @scroll < 0
					@scroll = 0
				end
				refresh_buffer
				Ncurses.doupdate
			end

			def wrap(str, max_size, prefix="")
				all = []
				line = ''
				str.split(/ /).each { |w|
					if rlen(line+w) >= max_size - rlen(prefix)
						all.push(line)
						line = ''
					end
					w ||= ' '
					line += line == '' ? w : ' ' + w
				}
				a = true
				all.push(line).collect { |i|
					if a
						i = prefix + i
						a = false
					else
						i = " " * rlen(prefix) + i
					end
					i
				}
			end
			private :wrap

			def addline(str, prefix="")
				if @global_prefix.kind_of?(String)
					dp = @global_prefix.dup
				elsif @global_prefix.respond_to?(:call)
					dp = @global_prefix.call
				end
				if !prefix.kind_of?(String)
					prefix = prefix.to_s
				end
				if dp
					prefix = dp + prefix
				end

				if str.respond_to?(:to_str)
					str.split(/\n/).each { |s|
						s.delete!("\r")
						@buflines.push([prefix.dup, s.dup])
						wrap(s, Ncurses.COLS, prefix).each { |l|
							@buffer.push(l)
						}
					}
				end
				refresh_buffer
				refresh_edit
				Ncurses.doupdate
				return str
			end
			
			def print(*args)
				args.each { |arg|
					self.addline(arg) if arg.respond_to?(:to_str)
				}
			end

			def columnize array, hash={}
				if @global_prefix.kind_of?(String)
					dp = @global_prefix.dup
				elsif @global_prefix.respond_to?(:call)
					dp = @global_prefix.call
				end

				hash['before_each']  ||= ''
				hash['after_each']	 ||= ''
				hash['between_each'] = ' '
				max_col_width = 0
				array.each { |s|
					if rlen(s) > max_col_width
						max_col_width = rlen(s)
					end
				}
				max_col_width += rlen(hash['before_each']) +
								 rlen(hash['after_each']) +
								 rlen(hash['between_each'])

				return nil if max_col_width > Ncurses.COLS - dp.length

				num_cols = (Ncurses.COLS - dp.length) / max_col_width
				num_rows = (array.length.to_f/num_cols.to_f).ceil

				# FIXME: There must be an easier way of doing this.
				cols = []
				i = 0
				col = 0
				array.each { |item|
					if i >= num_rows
						i = 0
						col += 1
					end
					cols[col] ||= []
					cols[col] << item
					i += 1
				}

				rows = []
				colsizes = []
				cols.each { |col|
					i = 0
					colsize = 0
					col.each { |item|
						rows[i] ||= []
						rows[i] << item
						colsize = item.length if item.length > colsize
						i += 1
					}
					colsizes << colsize
				}

				rows.each { |row|
					max_row_length = 0
					cnum = 0
					self.print row.collect { |it|
						s = "%s%-#{colsizes[cnum]}s%s" % [hash['before_each'],
													 	  it,
														  hash['after_each']]
						cnum += 1
						s
					}.join(hash['between_each'])
				}
			end

			def resize force=false
				rows = Ncurses.LINES
				cols = Ncurses.COLS

				if rows == @rows && cols == @cols && !force
					doupdate
					return
				end
				@rows = rows
				@cols = cols
				
				@buffer = Array.new
				@buflines.each { |prefix, line|
					wrap(line, Ncurses.COLS, prefix).each { |l|
						@buffer.push(l)
					}
				}

				setup_title
				setup_status
				setup_buffer
				setup_edit
				self.doupdate
			end

			def doupdate
				self.refresh_title
				self.refresh_buffer
				self.refresh_status
				self.refresh_edit
				Ncurses.doupdate
			end

			def buf_height
				ret = Ncurses.LINES - @editlines
				if @usetitle
					ret -= @titlelines
				end
				if @usestatus
					ret -= @statuslines
				end
			end

			def refresh_title
				if self != @parent.current_window || !@usetitle
					return
				end
				@title_win.erase
				@title_win.bkgd(@parent.palette["title"])
				title = @title.dup
				if title.length > Ncurses.COLS-2
					@titlelines.times { |i|
						str = title.slice(0, unrlen(title, Ncurses.COLS-2))
						do_colored_message(@title_win, i, 1, str, 'title')
					}
				else
					do_colored_message(@title_win, 0, 1, title, 'title')
				end
				@title_win.noutrefresh
			end

			def refresh_buffer
				if self != @parent.current_window
					return
				end
				@buffer_win.erase
				@buffer_win.bkgd(@parent.palette["default"])
				bh = self.buf_height
				buflines = @buffer.length > bh ? @buffer[-bh-@scroll, bh] :
					@buffer
				screen_y = 0
				for line in buflines
					self.do_colored_message(@buffer_win, screen_y, 0, line,
											'default')
					screen_y += 1
				end
				@buffer_win.noutrefresh
			end
			
			def refresh_status
				if self != @parent.current_window || !@usestatus
					return
				end
				@status_win.erase
				@status_win.bkgd(@parent.palette["status"])
				status = @status.dup
				if status.length > Ncurses.COLS-2
					@statuslines.times { |i|
						str = status.slice!(0, unrlen(status, Ncurses.COLS-2))
						do_colored_message(@status_win, i, 1, str, 'status')
					}
				else
					do_colored_message(@status_win, 0, 1, status, 'status')
				end
				@status_win.noutrefresh
			end

			def refresh_edit
				@edit_win.erase
				@edit_win.bkgd(@parent.palette["edit"])
				@edit_win.move(0, 1)
				str = @input.data.dup
				if str.length > Ncurses.COLS-2
					str.slice!(0, @input.cursor-Ncurses.COLS+2)
				end
				@edit_win.attrset(@parent.palette['edit'])
				@edit_win.addstr(str)
				@edit_win.move(0, @input.cursor+1)
				@edit_win.noutrefresh
			end

			def do_colored_message(win, y, x, message, default=nil)
				default ||= "default"
				default = "default" if !@parent.palette[default]

				win.attrset(@parent.palette[default])

				# re = /(^|[^%])%\((.+?)\)/

				if message !~ /(^|[^%])%\((.+?)\)/
					win.move(y, x)
					win.addstr(message)
					return
				end

				# '%(red)foo%(default)bar, %%(baz)%(blue)quux'
				# 'foobar %(red)bazquux'

				message.tokenize { |tok|
					case tok[0]
					when :tag
						if @parent.palette[tok[1]]
							win.attrset(@parent.palette[tok[1]])
						else
							win.attrset(@parent.palette[default])
						end
					when :text
						win.move(y, x)
						win.addstr(tok[1])
						x += tok[1].length
					end
				}
				win.attrset(@parent.palette[default])
			end

			def rlen(str)
=begin
				return str.length if str !~ /(^|[^%])%\(.+?\)/
				len = 0
				str.tokenize { |tok|
					if tok[0] == :text
						len += tok[1].length
					end
				}
				len
=end
				str = str.dup
				str.gsub!(/(\A|[^%])%\(.+?\)/, '\1')
				str.gsub!(/%%\((.+?)\)/, '%(\1)')
				str.length
				# BROKENX0R
				#(str.gsub(/(^|[^%])%\(.+?\)/, '') + ($1 ? $1 : '')).length
			end

			# where we should cut str if we want a string of len characters
			# with colors
			def unrlen(str, len)
=begin
				return len if str !~ /(^|[^%])%\(.+?\)/
				text = 0
				tag = 0
				str.tokenize { |tok|
					if tok[0] == :text
						text += tok[1].length
						if text >= len
							return len + tag
						end
					else
						tag += tok[1].length + 3 # %()
					end
				}
=end
				return len if str !~ /(?:\A|[^%])%\(.+?\)/
				ss = StringScanner.new(str.dup)
				pos = 0
				while m = ss.scan_until(/(\A|[^%])%\((.+?)\)/) and
						pos - ss.matched_size + (ss[1] ? ss[1].length : 0) <
						len do
					len += m.length - ss.pre_match.length -
						(ss[1] ? ss[1].length : 0)
					ss.string = ss.post_match
				end
				len
			end
		end
	end
end
