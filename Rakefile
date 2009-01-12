
require 'rubygems'
require 'rake/clean'
require 'fileutils'
 
task :default => :test
 
# SPECS ===============================================================
 
desc 'Run specs with unit test style output'
task :test do |t|
#  sh "specrb -s tests/*_test.rb"
  sh "specrb -s tests/6*_test.rb"
end
 
__END__

require 'rake'
require 'spec/rake/spectask'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Print specdocs"
Spec::Rake::SpecTask.new(:doc) do |t|
	t.spec_opts = ["--format", "specdoc", "--dry-run"]
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
	t.spec_files = FileList['spec/*_spec.rb']
	t.rcov = true
	t.rcov_opts = ['--exclude', 'examples']
end

task :default => :spec

######################################################

require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'fileutils'
include FileUtils

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
  s.extra_rdoc_files  = ['README.textile']
  
  # NOTE: how to make optional dependencies?
	#s.add_dependency 'mongrel'
	s.add_dependency 'rspec'
	s.add_dependency 'net-dns'
	#s.add_dependency 'session'

	s.platform = Gem::Platform::RUBY
	s.has_rdoc = true
	
	s.files = %w(Rakefile) + Dir.glob("{bin,doc,lib,spec,support,vendor}/**/**/*")
	
	s.require_path = "lib"
	s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
	p.need_tar = true if RUBY_PLATFORM !~ /mswin/
end


task :package => [ :zip ]


task :install => [ :rdoc, :package ] do
	sh %{sudo gem install pkg/#{name}-#{version}.gem}
end

task :uninstall => [ :clean ] do
	sh %{sudo gem uninstall #{name}}
end

Rake::TestTask.new do |t|
	t.libs << "spec"
	t.test_files = FileList['spec/*_spec.rb']
	t.verbose = true
end

Rake::RDocTask.new do |t|
	t.rdoc_dir = 'doc'
	t.title    = "stella, a friend in performance testing"
	t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
	t.options << '--charset' << 'utf-8'
	t.rdoc_files.include('LICENSE.txt')
	t.rdoc_files.include('README.txt')
	t.rdoc_files.include('lib/utils/*.rb')
	t.rdoc_files.include('lib/stella.rb')
	t.rdoc_files.include('lib/stella/*.rb')
	t.rdoc_files.include('lib/stella/**/*.rb')
end

CLEAN.include [ 'pkg', '*.gem', '.config', 'doc' ]


