require 'ftools'

module FileUtil
  
  def FileUtil.read_file(path)
    FileUtil.read_file_to_array(path).join('')
  end
  
  def FileUtil.read_file_to_array(path)
    contents = []
    return contents unless File.exists?(path)
    
    open(path, 'r') do |l|
      contents = l.readlines
    end

    contents
  end
  def FileUtil.read_binary_file(path)
    contents = ''
    return contents unless File.exists?(path)
    
    open(path, 'rb') do |l|
      while (!l.eof?)
        contents << l.read(4096)
      end
    end

    contents
  end
  
  
  
  def FileUtil.write_file(path, content, flush=true)
    FileUtil.write_or_append_file('w', path, content, flush)
  end
  
  def FileUtil.append_file(path, content, flush=true)
    FileUtil.write_or_append_file('a', path, content, flush)
  end
  
  def FileUtil.write_or_append_file(write_or_append, path, content = '', flush = true)
    #STDERR.puts "Writing to #{ path }..." 
    FileUtil.create_dir(File.dirname(path))
    
    open(path, write_or_append) do |f| 
      f.puts content
      f.flush if flush;
    end
    File.chmod(0600, path)
  end
  
  def FileUtil.create_dir(dirpath)
    return if File.directory?(dirpath)
    
    #STDERR.puts "Creating #{ dirpath }"
    File.makedirs(dirpath)
  end
end