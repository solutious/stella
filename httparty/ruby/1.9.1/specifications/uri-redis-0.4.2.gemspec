# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{uri-redis}
  s.version = "0.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2010-12-23}
  s.description = %q{URI-Redis: support for parsing redis://host:port/dbindex/keyname}
  s.email = %q{delano@solutious.com}
  s.extra_rdoc_files = ["LICENSE.txt", "README.rdoc"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "VERSION.yml", "lib/uri/redis.rb", "try/10_uri_redis_try.rb"]
  s.homepage = %q{http://github.com/delano/uri-redis}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{uri-redis}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{URI-Redis: support for parsing redis://host:port/dbindex/keyname}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
