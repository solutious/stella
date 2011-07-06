# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rye}
  s.version = "0.9.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2011-02-14}
  s.description = %q{Rye: Safely run SSH commands on a bunch of machines at the same time (from Ruby).}
  s.email = %q{delano@solutious.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "Rudyfile", "bin/try", "lib/esc.rb", "lib/rye.rb", "lib/rye/box.rb", "lib/rye/cmd.rb", "lib/rye/key.rb", "lib/rye/rap.rb", "lib/rye/set.rb", "lib/rye/hop.rb", "rye.gemspec"]
  s.homepage = %q{http://github.com/delano/rye/}
  s.rdoc_options = ["--line-numbers", "--title", "Rye: Safely run SSH commands on a bunch of machines at the same time (from Ruby).", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rye}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Rye: Safely run SSH commands on a bunch of machines at the same time (from Ruby).}

  if s.respond_to? :specification_version then
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<annoy>, [">= 0"])
      s.add_runtime_dependency(%q<sysinfo>, [">= 0.7.3"])
      s.add_runtime_dependency(%q<highline>, [">= 1.5.1"])
      s.add_runtime_dependency(%q<net-ssh>, [">= 2.0.13"])
      s.add_runtime_dependency(%q<net-scp>, [">= 1.0.2"])
    else
      s.add_dependency(%q<annoy>, [">= 0"])
      s.add_dependency(%q<sysinfo>, [">= 0.7.3"])
      s.add_dependency(%q<highline>, [">= 1.5.1"])
      s.add_dependency(%q<net-ssh>, [">= 2.0.13"])
      s.add_dependency(%q<net-scp>, [">= 1.0.2"])
    end
  else
    s.add_dependency(%q<annoy>, [">= 0"])
    s.add_dependency(%q<sysinfo>, [">= 0.7.3"])
    s.add_dependency(%q<highline>, [">= 1.5.1"])
    s.add_dependency(%q<net-ssh>, [">= 2.0.13"])
    s.add_dependency(%q<net-scp>, [">= 1.0.2"])
  end
end
