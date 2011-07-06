@spec = Gem::Specification.new do |s|
  s.name = "benelux"
  s.rubyforge_project = 'benelux'
  s.version = "0.6.1"
  s.summary = "Benelux: A mad way to time Ruby codes"
  s.description = s.summary
  s.author = "Delano Mandelbaum"
  s.email = "delano@solutious.com"
  s.homepage = "http://github.com/delano/benelux"
  
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt CHANGES.txt]
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.rdoc"]
  s.require_paths = %w[lib]
  
  s.add_dependency("attic", ">= 0.5.3")
  s.add_dependency("storable", ">= 0.8.6")
  
  # = MANIFEST =
  # git ls-files
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.rdoc
  Rakefile
  benelux.gemspec
  lib/benelux.rb
  lib/benelux/mark.rb
  lib/benelux/mixins.rb
  lib/benelux/packer.rb
  lib/benelux/range.rb
  lib/benelux/stats.rb
  lib/benelux/timeline.rb
  lib/benelux/track.rb
  lib/selectable.rb
  lib/selectable/global.rb
  lib/selectable/object.rb
  lib/selectable/tags.rb
  )

  
end
