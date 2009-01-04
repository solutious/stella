require 'fileutils'

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
  
  def FileUtil.create_file(filepath, perm='w', file_perms=nil, force=false)
    raise Exception.new("File #{filepath} already exists!") if File.exists?(filepath) && !force
    
    newfile = File.new(filepath, perm)
    if file_perms && File.exists?(file_perms)
      File.chown(File.stat(file_perms).uid.to_i, File.stat(file_perms).gid.to_i, filepath)
    end
    newfile
  end

  def FileUtil.create_dir(dirpath, dir_perms=nil)
    return if File.directory?(dirpath)
    
    #STDERR.puts "Creating #{ dirpath }"
    FileUtils.makedirs(dirpath)
    
    if dir_perms && File.exists?(dir_perms)
      File.chown(File.stat(dir_perms).uid.to_i, File.stat(dir_perms).gid.to_i, dirpath)
    end
    
  end
end