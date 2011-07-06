# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sysinfo}
  s.version = "0.7.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2010-02-20}
  s.default_executable = %q{sysinfo}
  s.description = %q{SysInfo: All your system-independent infoz in one handy class.}
  s.email = %q{delano@solutious.com}
  s.executables = ["sysinfo"]
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "bin/sysinfo", "lib/sysinfo.rb", "sysinfo.gemspec"]
  s.homepage = %q{http://solutious.com/}
  s.rdoc_options = ["--line-numbers", "--title", "SysInfo: All your system-independent infoz in one handy class.", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{sysinfo}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{SysInfo: All your system-independent infoz in one handy class.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<storable>, [">= 0"])
      s.add_runtime_dependency(%q<drydock>, [">= 0"])
    else
      s.add_dependency(%q<storable>, [">= 0"])
      s.add_dependency(%q<drydock>, [">= 0"])
    end
  else
    s.add_dependency(%q<storable>, [">= 0"])
    s.add_dependency(%q<drydock>, [">= 0"])
  end
end
