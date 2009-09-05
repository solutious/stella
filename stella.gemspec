@spec = Gem::Specification.new do |s|
  s.name = "stella"
  s.rubyforge_project = 'stella'
  s.version = "0.7.0.001"
  s.summary = "Stella: Your friend in performance testing."
  s.description = s.summary
  s.author = "Delano Mandelbaum"
  s.email = "delano@solutious.com"
  s.homepage = "http://solutious.com/projects/stella/"
  
  s.extra_rdoc_files = %w[README.rdoc Rudyfile LICENSE.txt CHANGES.txt]
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.rdoc"]
  s.require_paths = %w[lib]
  
  s.executables = %w[stella]
  
  s.add_dependency 'rye',        '>= 0.8.9'
  s.add_dependency 'drydock',    '>= 0.6.6'
  s.add_dependency 'caesars',    '>= 0.7.3'
  s.add_dependency 'gibbler',    '>= 0.6.0'
  s.add_dependency 'tryouts',    '>= 0.8.4'
  s.add_dependency 'storable',   '>= 0.5.6'
  
  # = MANIFEST =
  # git ls-files
  s.files = %w(
  
  )

  
end
