# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{storable}
  s.version = "0.8.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2011-05-21}
  s.description = %q{Storable: Marshal Ruby classes into and out of multiple formats (yaml, json, csv, tsv)}
  s.email = %q{delano@solutious.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "lib/proc_source.rb", "lib/storable.rb", "lib/storable/orderedhash.rb", "storable.gemspec"]
  s.homepage = %q{http://github.com/delano/storable/}
  s.rdoc_options = ["--line-numbers", "--title", "Storable: Marshal Ruby classes into and out of multiple formats (yaml, json, csv, tsv)", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{storable}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Storable: Marshal Ruby classes into and out of multiple formats (yaml, json, csv, tsv)}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
