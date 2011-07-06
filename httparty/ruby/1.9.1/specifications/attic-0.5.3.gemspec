# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{attic}
  s.version = "0.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2011-02-11}
  s.description = %q{A place to hide private instance variables in your Ruby objects.}
  s.email = %q{delano@solutious.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt", "CHANGES.txt"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "attic.gemspec", "lib/attic.rb", "try/01_mixins_tryouts.rb", "try/10_attic_tryouts.rb", "try/20_accessing_tryouts.rb", "try/25_string_tryouts.rb", "try/30_nometaclass_tryouts.rb", "try/40_explicit_accessor_tryouts.rb", "try/X1_metaclasses.rb", "try/X2_extending.rb"]
  s.homepage = %q{http://github.com/delano/attic}
  s.rdoc_options = ["--line-numbers", "--title", "A place to hide private instance variables in your Ruby objects.", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{attic}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{A place to hide private instance variables in your Ruby objects.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
