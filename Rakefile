
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
  sh "specrb -s tests/*_test.rb"
end

# PACKAGE =============================================================


STELLA_HOME = File.expand_path(File.join(File.dirname(__FILE__)))
$: << File.join(STELLA_HOME, 'lib')

require 'stella'
name = 'stella'
version = Stella::VERSION.to_s

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
	s.add_dependency 'cucumber'
	s.add_dependency 'fastthread'
	s.add_dependency 'hoe'
	s.add_dependency 'rake'
	s.add_dependency 'rubyforge'
	

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


# Rubyforge Release / Publish Tasks ==================================

desc 'Publish website to rubyforge'
task 'publish:doc' => 'doc/index.html' do
  sh 'scp -rp doc/* rubyforge.org:/var/www/gforge-projects/stella/'
end

#task 'publish:gem' => [package('.gem'), package('.tar.gz')] do |t|
#  sh <<-end
#    rubyforge add_release stella stella #{spec.version} #{package('.gem')} &&
#    rubyforge add_file    stella stella #{spec.version} #{package('.tar.gz')}
#  end
#end


Rake::RDocTask.new do |t|
	t.rdoc_dir = 'doc'
	t.title    = "stella, a friend in performance testing"
	t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
	t.options << '--charset' << 'utf-8'
	t.rdoc_files.include('LICENSE.txt')
	t.rdoc_files.include('README.rdoc')
	t.rdoc_files.include('CHANGES.txt')
	t.rdoc_files.include('bin/*')
	t.rdoc_files.include('lib/utils/*.rb')
	t.rdoc_files.include('lib/stella.rb')
	t.rdoc_files.include('lib/stella/**/*.rb')
end

CLEAN.include [ 'pkg', '*.gem', '.config', 'doc' ]



