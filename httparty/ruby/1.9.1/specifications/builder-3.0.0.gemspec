# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{builder}
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jim Weirich"]
  s.autorequire = %q{builder}
  s.date = %q{2010-11-17}
  s.description = %q{Builder provides a number of builder objects that make creating structured data
simple to do.  Currently the following builder objects are supported:

* XML Markup
* XML Events
}
  s.email = %q{jim@weirichhouse.org}
  s.extra_rdoc_files = ["CHANGES", "Rakefile", "README", "README.rdoc", "TAGS", "doc/releases/builder-1.2.4.rdoc", "doc/releases/builder-2.0.0.rdoc", "doc/releases/builder-2.1.1.rdoc"]
  s.files = ["lib/blankslate.rb", "lib/builder/blankslate.rb", "lib/builder/xchar.rb", "lib/builder/xmlbase.rb", "lib/builder/xmlevents.rb", "lib/builder/xmlmarkup.rb", "lib/builder.rb", "test/performance.rb", "test/preload.rb", "test/test_blankslate.rb", "test/test_cssbuilder.rb", "test/test_eventbuilder.rb", "test/test_markupbuilder.rb", "test/test_namecollision.rb", "test/test_xchar.rb", "CHANGES", "Rakefile", "README", "README.rdoc", "TAGS", "doc/releases/builder-1.2.4.rdoc", "doc/releases/builder-2.0.0.rdoc", "doc/releases/builder-2.1.1.rdoc"]
  s.homepage = %q{http://onestepback.org}
  s.rdoc_options = ["--title", "Builder -- Easy XML Building", "--main", "README.rdoc", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Builders for MarkUp.}
  s.test_files = ["test/test_blankslate.rb", "test/test_cssbuilder.rb", "test/test_eventbuilder.rb", "test/test_markupbuilder.rb", "test/test_namecollision.rb", "test/test_xchar.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
