STELLA_HOME = File.expand_path(File.join(File.dirname(__FILE__)))
$: << File.join(STELLA_HOME, 'lib')

require 'stella'
version = Stella::VERSION.to_s
name = "stella"

Gem::Specification.new do |s|
	s.name = name
	s.version = version
	s.summary = "Your friend in performance testing."
	s.description = "Run Apache Bench, Siege, or httperf tests in batches and aggregate results."
	s.author = "Delano Mandelbaum"
	s.email = "delano@solutious.com"
	s.homepage = "http://stella.solutious.com/"
	s.executables = [ "stella", "stella.bat" ]
	s.rubyforge_project = "stella"
  s.extra_rdoc_files  = ['README.textile']
  
  # NOTE: how to make optional dependencies?
	s.add_dependency 'rspec'
	s.add_dependency 'net-dns'
	s.add_dependency 'mongrel'

	s.platform = Gem::Platform::RUBY
	s.has_rdoc = true
	
	s.files = %w(Rakefile) + Dir.glob("{bin,doc,lib,test,support,vendor}/**/**/*")
	
	s.require_path = "lib"
	s.bindir = "bin"
end