@spec = Gem::Specification.new do |s|
  s.name = %q{drydock}
  s.version = "0.6.9"
  s.specification_version = 1 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.authors = ["Delano Mandelbaum"]
  s.description = %q{Build seaworthy command-line apps like a Captain with a powerful Ruby DSL.}
  s.summary = s.description
  s.email = %q{delano@solutious.com}

  # = MANIFEST =
  # git ls-files
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.rdoc
  Rakefile
  bin/example
  drydock.gemspec
  lib/drydock.rb
  lib/drydock/console.rb
  lib/drydock/mixins.rb
  lib/drydock/mixins/object.rb
  lib/drydock/mixins/string.rb
  lib/drydock/screen.rb
  )

  #  s.add_dependency ''

  s.has_rdoc = true
  s.homepage = %q{http://github.com/delano/drydock}
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt CHANGES.txt]
  s.rdoc_options = ["--line-numbers", "--title", "Drydock: #{s.description}", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.1.1}
  s.rubyforge_project = "drydock"
end
