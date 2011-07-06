# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{benelux}
  s.version = "0.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2011-02-11}
  s.description = %q{Benelux: A mad way to time Ruby codes}
  s.email = %q{delano@solutious.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt", "CHANGES.txt"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "benelux.gemspec", "lib/benelux.rb", "lib/benelux/mark.rb", "lib/benelux/mixins.rb", "lib/benelux/packer.rb", "lib/benelux/range.rb", "lib/benelux/stats.rb", "lib/benelux/timeline.rb", "lib/benelux/track.rb", "lib/selectable.rb", "lib/selectable/global.rb", "lib/selectable/object.rb", "lib/selectable/tags.rb"]
  s.homepage = %q{http://github.com/delano/benelux}
  s.rdoc_options = ["--line-numbers", "--title", "Benelux: A mad way to time Ruby codes", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{benelux}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Benelux: A mad way to time Ruby codes}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<attic>, [">= 0.5.3"])
      s.add_runtime_dependency(%q<storable>, [">= 0.8.6"])
    else
      s.add_dependency(%q<attic>, [">= 0.5.3"])
      s.add_dependency(%q<storable>, [">= 0.8.6"])
    end
  else
    s.add_dependency(%q<attic>, [">= 0.5.3"])
    s.add_dependency(%q<storable>, [">= 0.8.6"])
  end
end
