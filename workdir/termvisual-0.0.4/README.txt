== What Is This Library?

This library allows you to quickly and simply create
irssi/ircII-style multi-window ncurses-based interfaces.

At the current stage of development, there is no way to switch
between windows. However, this functionality is planned for a future
release.

== Examples

=== Simple Term::Visual use

    require 'term/visual'
    
    vt = Term::Visual.new
    window = vt.create_window(
        'title'	=> "Window Title",
        'status'	=> "Status bar"
    )
    
    window.print "foobar"

    loop do
        if line = vt.getline
            window.print line
        end

        sleep 0.0001
    end

=== Using colors

    require 'term/visual'

    vt = Term::Visual.new

    vt.palette.setcolors(
        'title'	=> 'red on green',
        'foo'		=> 'bold cyan on default',
        'bar'		=> 'bold red on blue',
        'baz'		=> 'bold green on blue'
    )
    
    window = vt.create_window('title' => "window")
    
    window.title = "%(baz)Colors!"
    window.status = "%(bar)Colors%(status) in the status bar."

    window.print "We can have %(foo)colors%(default) here, too.

    loop do
        if line = vt.getline
            window.print line
        end

        sleep 0.0001
    end

=== Using prefixes

    require 'term/visual'
    
    vt = Term::Visual.new
    vt.palette.setcolors(
        'item'			=> 'bold green on default'
        'itemdecorations'	=> 'bold black on default'
    )

    vt.global_prefix = lambda { Time.now.strftime("%H:%M:%S ") }

    # The global prefix goes before every line. Wrapped lines with a
    # prefix will start at the prefix.
    # Example:
    # vt.addline "This is some text " * 5, "prefix: "
    # Produces in the window something like:
    # prefix: This is some text This is some text This is some text Th
    #         is is some text This is some text
    #
    # (lines are not currently wrapped at words.)
    # 
    # With that global prefix we set, that line would look something
    # like this:
    # 20:34:17 prefix: This is some text This is some text This is som
    #                  e text This is some text This is some text

    window = vt.create_window('title' => "window")
    
    window.print "A line."
    window.addline "A line.", "%(itemdecorations)<%(item)" +
        "nickname%(itemdecorations)>%(default)"

    loop do
        [...]
    end
    
