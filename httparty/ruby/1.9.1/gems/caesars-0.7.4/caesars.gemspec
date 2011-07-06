@spec = Gem::Specification.new do |s|
  s.name = "caesars"
  s.rubyforge_project = "caesars"
  s.version = "0.7.4"
  s.specification_version = 1 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.authors = ["Delano Mandelbaum"]
  s.description = %q{Rapid DSL prototyping in Ruby.}
  s.summary = %q{Caesars: Rapid DSL prototyping in Ruby.}
  s.email = %q{delano@solutious.com}

  # = MANIFEST =
  # git ls-files
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.rdoc
  Rakefile
  bin/example
  bin/example.bat
  bin/party.conf
  caesars.gemspec
  lib/caesars.rb
  lib/caesars/config.rb
  lib/caesars/exceptions.rb
  lib/caesars/hash.rb
  lib/caesars/orderedhash.rb
  )

  #  s.add_dependency ''

  s.has_rdoc = true
  s.homepage = %q{http://github.com/delano/caesars}
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt CHANGES.txt]
  s.rdoc_options = ["--line-numbers", "--title", "Caesars: Rapid DSL prototyping in Ruby.", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.1.1"
end
