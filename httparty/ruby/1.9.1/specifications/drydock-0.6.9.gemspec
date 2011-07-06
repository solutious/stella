# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{drydock}
  s.version = "0.6.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2010-02-12}
  s.description = %q{Build seaworthy command-line apps like a Captain with a powerful Ruby DSL.}
  s.email = %q{delano@solutious.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt", "CHANGES.txt"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "bin/example", "drydock.gemspec", "lib/drydock.rb", "lib/drydock/console.rb", "lib/drydock/mixins.rb", "lib/drydock/mixins/object.rb", "lib/drydock/mixins/string.rb", "lib/drydock/screen.rb"]
  s.homepage = %q{http://github.com/delano/drydock}
  s.rdoc_options = ["--line-numbers", "--title", "Drydock: Build seaworthy command-line apps like a Captain with a powerful Ruby DSL.", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{drydock}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Build seaworthy command-line apps like a Captain with a powerful Ruby DSL.}

  if s.respond_to? :specification_version then
    s.specification_version = 1

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
