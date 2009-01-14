
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
 
  s.name = 'stella'
  s.version = '0.5.5'
  s.date = '2009-01-14'
 
  s.description = "Your friend in performance testing."
  s.summary = "Run Apache Bench, Siege, or httperf tests in batches and aggregate results."
  s.authors = ["Delano Mandelbaum"]
  s.homepage = "http://github.com/solutious/stella"
 
  # = MANIFEST =
  s.files = %w(Rakefile) + Dir.glob("{bin,doc,lib,test,support,vendor}/**/**/*")
  
  s.test_files = s.files.select {|path| path =~ /^test\/.*_test.rb/}

  s.extra_rdoc_files = %w[README.textile LICENSE]
	s.add_dependency 'net-dns'
	s.add_dependency 'mongrel'
	
  s.has_rdoc = true
  
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Stella", "--main", "README.textile"]
  s.bindir = "bin"
  s.executables = [ "stella", "stella.bat" ]
  s.require_paths = %w[lib vendor]
  s.rubyforge_project = 'stella'
  s.rubygems_version = '1.1.1'
  
end