# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{caesars}
  s.version = "0.7.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2010-02-15}
  s.description = %q{Rapid DSL prototyping in Ruby.}
  s.email = %q{delano@solutious.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt", "CHANGES.txt"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "bin/example", "bin/example.bat", "bin/party.conf", "caesars.gemspec", "lib/caesars.rb", "lib/caesars/config.rb", "lib/caesars/exceptions.rb", "lib/caesars/hash.rb", "lib/caesars/orderedhash.rb"]
  s.homepage = %q{http://github.com/delano/caesars}
  s.rdoc_options = ["--line-numbers", "--title", "Caesars: Rapid DSL prototyping in Ruby.", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{caesars}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Caesars: Rapid DSL prototyping in Ruby.}

  if s.respond_to? :specification_version then
    s.specification_version = 1

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
