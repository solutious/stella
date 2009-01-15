
require 'rubygems'
require 'rake/clean'
require 'rake/gempackagetask'
require 'hanna/rdoctask'
require 'fileutils'
include FileUtils
 
task :default => :test
 
# SPECS ===============================================================
 
desc 'Run specs with unit test style output'
task :test do |t|
#  sh "specrb -s tests/*_test.rb"
  sh "specrb -s tests/*_test.rb"
end

# PACKAGE =============================================================


STELLA_HOME = File.expand_path(File.join(File.dirname(__FILE__)))
$: << File.join(STELLA_HOME, 'lib')

require 'stella'
version = Stella::VERSION.to_s
name = "stella"

spec = Gem::Specification.new do |s|
	s.name = name
	s.version = version
	s.summary = "Your friend in performance testing."
	s.description = "Run Apache Bench, Siege, or httperf tests in batches and aggregate results."
	s.author = "Delano Mandelbaum"
	s.email = "delano@solutious.com"
	s.homepage = "http://stella.solutious.com/"
	s.executables = [ "stella", "stella.bat" ]
	s.rubyforge_project = "stella"
  s.extra_rdoc_files  = ['README.rdoc']
  
  # NOTE: how to make optional dependencies?
	s.add_dependency 'mongrel'
	s.add_dependency 'rspec'
	s.add_dependency 'net-dns'

	s.platform = Gem::Platform::RUBY
	s.has_rdoc = true
	
	s.files = %w(Rakefile) + Dir.glob("{bin,doc,lib,tests,support,vendor}/**/**/*")
	
	s.require_path = "lib"
	s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
	p.need_tar = true if RUBY_PLATFORM !~ /mswin/
end



task :install => [ :rdoc, :package ] do
	sh %{sudo gem install pkg/#{name}-#{version}.gem}
end

task :uninstall => [ :clean ] do
	sh %{sudo gem uninstall #{name}}
end



Rake::RDocTask.new do |t|
	t.rdoc_dir = 'doc'
	t.title    = "stella, a friend in performance testing"
	t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
	t.options << '--charset' << 'utf-8'
	t.rdoc_files.include('LICENSE.txt')
	t.rdoc_files.include('README.rdoc')
	t.rdoc_files.include('CHANGES.txt')
	t.rdoc_files.include('lib/utils/*.rb')
	t.rdoc_files.include('lib/stella.rb')
	t.rdoc_files.include('lib/stella/**/*.rb')
end

CLEAN.include [ 'pkg', '*.gem', '.config', 'doc' ]



