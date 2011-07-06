# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{familia}
  s.version = "0.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2011-04-11}
  s.description = %q{Organize and store ruby objects in Redis}
  s.email = %q{delano@solutious.com}
  s.extra_rdoc_files = ["LICENSE.txt", "README.rdoc"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "VERSION.yml", "familia.gemspec", "lib/familia.rb", "lib/familia/core_ext.rb", "lib/familia/helpers.rb", "lib/familia/object.rb", "lib/familia/redisobject.rb", "lib/familia/test_helpers.rb", "lib/familia/tools.rb", "try/00_familia.rb", "try/10_familia_try.rb", "try/20_redis_object_try.rb", "try/21_redis_object_zset_try.rb", "try/22_redis_object_set_try.rb", "try/23_redis_object_list_try.rb", "try/24_redis_object_string_try.rb", "try/25_redis_object_hash_try.rb", "try/30_familia_object_try.rb"]
  s.homepage = %q{http://github.com/delano/familia}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{familia}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Organize and store ruby objects in Redis}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redis>, [">= 2.1.0"])
      s.add_runtime_dependency(%q<uri-redis>, [">= 0.4.2"])
      s.add_runtime_dependency(%q<gibbler>, [">= 0.8.6"])
      s.add_runtime_dependency(%q<storable>, [">= 0.8.6"])
      s.add_runtime_dependency(%q<multi_json>, [">= 0.0.5"])
    else
      s.add_dependency(%q<redis>, [">= 2.1.0"])
      s.add_dependency(%q<uri-redis>, [">= 0.4.2"])
      s.add_dependency(%q<gibbler>, [">= 0.8.6"])
      s.add_dependency(%q<storable>, [">= 0.8.6"])
      s.add_dependency(%q<multi_json>, [">= 0.0.5"])
    end
  else
    s.add_dependency(%q<redis>, [">= 2.1.0"])
    s.add_dependency(%q<uri-redis>, [">= 0.4.2"])
    s.add_dependency(%q<gibbler>, [">= 0.8.6"])
    s.add_dependency(%q<storable>, [">= 0.8.6"])
    s.add_dependency(%q<multi_json>, [">= 0.0.5"])
  end
end
