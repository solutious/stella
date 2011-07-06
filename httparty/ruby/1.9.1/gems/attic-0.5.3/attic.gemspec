@spec = Gem::Specification.new do |s|
	s.name = "attic"
  s.rubyforge_project = "attic"
	s.version = "0.5.3"
	s.summary = "A place to hide private instance variables in your Ruby objects."
	s.description = s.summary
	s.author = "Delano Mandelbaum"
	s.email = "delano@solutious.com"
	s.homepage = "http://github.com/delano/attic"
  
  # = EXECUTABLES =
  # The list of executables in your project (if any). Don't include the path, 
  # just the base filename.
  s.executables = %w[]
  
  # Directories to extract rdocs from
  s.require_paths = %w[lib]  
  
  # Specific files to include rdocs from
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt CHANGES.txt]
  
  # Update --main to reflect the default page to display
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.rdoc"]
  
  # = MANIFEST =
  # The complete list of files to be included in the release. When GitHub packages your gem, 
  # it doesn't allow you to run any command that accesses the filesystem. You will get an
  # error. You can ask your VCS for the list of versioned files:
  # git ls-files
  # svn list -R
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.rdoc
  Rakefile
  attic.gemspec
  lib/attic.rb
  try/01_mixins_tryouts.rb
  try/10_attic_tryouts.rb
  try/20_accessing_tryouts.rb
  try/25_string_tryouts.rb
  try/30_nometaclass_tryouts.rb
  try/40_explicit_accessor_tryouts.rb
  try/X1_metaclasses.rb
  try/X2_extending.rb
  )
  
  s.has_rdoc = true
  s.rubygems_version = '1.3.0'

  
end