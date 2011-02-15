require "rubygems"
require "rake"
require "rake/clean"
require 'yaml'

begin
  require 'hanna/rdoctask'
rescue LoadError
  require 'rake/rdoctask'
end
 
config = YAML.load_file("VERSION.yml")
task :default => ["build"]
CLEAN.include [ 'pkg', 'doc' ]
name = "stella"

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.version = "#{config[:MAJOR]}.#{config[:MINOR]}.#{config[:PATCH]}.#{config[:BUILD]}"
    gem.name = "stella"
    gem.rubyforge_project = gem.name
    gem.summary = "Blame Stella for breaking your web application!"
    gem.description = "Blame Stella for breaking your web application!"
    gem.email = "delano@solutious.com"
    gem.homepage = "http://blamestella.com/"
    gem.authors = ["Delano Mandelbaum"]
    gem.add_dependency("gibbler",    ">= 0.8.1")
    gem.add_dependency("drydock",    ">= 0.6.9")
    gem.add_dependency("benelux",    "= 0.5.15")
    gem.add_dependency('sysinfo',    '>= 0.7.3')
    gem.add_dependency('storable',   '>= 0.7.3')
    gem.add_dependency("nokogiri")

    #gem.add_development_dependency("rspec", ">= 1.2.9")
    #gem.add_development_dependency("mocha", ">= 0.9.8")
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end


Rake::RDocTask.new do |rdoc|
  version = "#{config[:MAJOR]}.#{config[:MINOR]}.#{config[:PATCH]}.#{config[:BUILD]}"
  rdoc.rdoc_dir = "doc"
  rdoc.title = "stella #{version}"
  rdoc.rdoc_files.include("README*")
  rdoc.rdoc_files.include("LICENSE.txt")
  rdoc.rdoc_files.include("bin/*.rb")
  rdoc.rdoc_files.include("lib/**/*.rb")
end


# Rubyforge Release / Publish Tasks ==================================

#about 'Publish website to rubyforge'
task 'publish:rdoc' => 'doc/index.html' do
  sh "scp -rp doc/* rubyforge.org:/var/www/gforge-projects/#{name}/"
end

#about 'Public release to rubyforge'
task 'publish:gem' => [:package] do |t|
  sh <<-end
    rubyforge add_release -o Any -a CHANGES.txt -f -n README.md #{name} #{name} #{@spec.version} pkg/#{name}-#{@spec.version}.gem &&
    rubyforge add_file -o Any -a CHANGES.txt -f -n README.md #{name} #{name} #{@spec.version} pkg/#{name}-#{@spec.version}.tgz 
  end
end




