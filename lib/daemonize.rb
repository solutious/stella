module Daemonize
  VERSION = "0.1.2"

  # Try to fork if at all possible retrying every 5 sec if the
  # maximum process limit for the system has been reached
  def safefork
    tryagain = true

    while tryagain
      tryagain = false
      begin
        if pid = fork
          return pid
        end
      rescue Errno::EWOULDBLOCK
        sleep 5
        tryagain = true
      end
    end
  end

  # This method causes the current running process to become a daemon
  # If closefd is true, all existing file descriptors are closed
  def daemonize(oldmode=0, closefd=false)
    srand # Split rand streams between spawning and daemonized process
    safefork and exit # Fork and exit from the parent

    # Detach from the controlling terminal
    unless sess_id = Process.setsid
      raise 'Cannot detach from controlled terminal'
    end

    # Prevent the possibility of acquiring a controlling terminal
    if oldmode.zero?
      trap 'SIGHUP', 'IGNORE'
      exit if pid = safefork
    end

    Dir.chdir "/"   # Release old working directory
    File.umask 0000 # Insure sensible umask

    if closefd
      # Make sure all file descriptors are closed
      ObjectSpace.each_object(IO) do |io|
        unless [STDIN, STDOUT, STDERR].include?(io)
          io.close rescue nil
        end
      end
    end

    STDIN.reopen "/dev/null"       # Free file descriptors and
    STDOUT.reopen "/dev/null", "a" # point them somewhere sensible
    STDERR.reopen STDOUT           # STDOUT/STDERR should go to a logfile
    return oldmode ? sess_id : 0   # Return value is mostly irrelevant
  end
end
