# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{annoy}
  s.version = "0.5.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2010-02-20}
  s.description = %q{Annoy: Like your annoying friend that asks you questions all the time.}
  s.email = %q{delano@solutious.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "lib/annoy.rb", "annoy.gemspec"]
  s.homepage = %q{http://solutious.com/}
  s.rdoc_options = ["--line-numbers", "--title", "Annoy: Like your annoying friend that asks you questions all the time.", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{annoy}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Annoy: Like your annoying friend that asks you questions all the time.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<highline>, [">= 1.5.0"])
    else
      s.add_dependency(%q<highline>, [">= 1.5.0"])
    end
  else
    s.add_dependency(%q<highline>, [">= 1.5.0"])
  end
end
