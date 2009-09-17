@spec = Gem::Specification.new do |s|
  s.name = "stella"
  s.rubyforge_project = 'stella'
  s.version = "0.7.0.004"
  s.summary = "Stella: Your friend in performance testing."
  s.description = s.summary
  s.author = "Delano Mandelbaum"
  s.email = "delano@solutious.com"
  s.homepage = "http://solutious.com/projects/stella/"
  
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt CHANGES.txt]
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.rdoc"]
  s.require_paths = %w[lib]
  
  s.executables = %w[stella]
  
  s.add_dependency 'drydock',    '>= 0.6.8'
  s.add_dependency 'gibbler',    '>= 0.6.2'
  s.add_dependency 'storable',   '>= 0.5.7'
  s.add_dependency 'httpclient', '>= 2.1.5'
  s.add_dependency 'nokogiri'
  
  # = MANIFEST =
  # git ls-files
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.rdoc
  Rakefile
  bin/stella
  examples/basic/plan.rb
  examples/basic/search_terms.csv
  examples/example_webapp.rb
  examples/exceptions/plan.rb
  lib/stella.rb
  lib/stella/cli.rb
  lib/stella/client.rb
  lib/stella/config.rb
  lib/stella/data.rb
  lib/stella/data/http.rb
  lib/stella/data/http/body.rb
  lib/stella/data/http/request.rb
  lib/stella/data/http/response.rb
  lib/stella/dsl.rb
  lib/stella/engine.rb
  lib/stella/engine/functional.rb
  lib/stella/engine/load.rb
  lib/stella/exceptions.rb
  lib/stella/guidelines.rb
  lib/stella/mixins.rb
  lib/stella/stats.rb
  lib/stella/testplan.rb
  lib/stella/testplan/stats.rb
  lib/stella/testplan/usecase.rb
  lib/stella/utils.rb
  lib/stella/utils/httputil.rb
  lib/stella/version.rb
  lib/threadify.rb
  stella.gemspec
  support/useragents.txt
  )

  
end
