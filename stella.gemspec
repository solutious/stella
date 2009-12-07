@spec = Gem::Specification.new do |s|
  s.name = "stella"
  s.rubyforge_project = 'stella'
  s.version = "0.8.0.000"
  s.summary = "Blame Stella for breaking your web applications."
  s.description = s.summary
  s.author = "Delano Mandelbaum"
  s.email = "delano@solutious.com"
  s.homepage = "http://solutious.com/projects/stella/"
  
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt CHANGES.txt]
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.rdoc"]
  s.require_paths = %w[lib]
  
  s.executables = %w[stella]
  
  s.add_dependency 'benelux',    '>= 0.5.3'
  s.add_dependency 'drydock',    '>= 0.6.8'
  s.add_dependency 'gibbler',    '>= 0.7.1'
  s.add_dependency 'sysinfo',    '>= 0.7.1'
  s.add_dependency 'storable',   '>= 0.6.0'
  s.add_dependency 'nokogiri'
  
  # = MANIFEST =
  # git ls-files
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.rdoc
  Rakefile
  Rudyfile
  bin/stella
  examples/cookies/plan.rb
  examples/csvdata/plan.rb
  examples/csvdata/search_terms.csv
  examples/essentials/logo.png
  examples/essentials/plan.rb
  examples/essentials/search_terms.txt
  examples/exceptions/plan.rb
  lib/proc_source.rb
  lib/stella.rb
  lib/stella/cli.rb
  lib/stella/client.rb
  lib/stella/client/container.rb
  lib/stella/common.rb
  lib/stella/data.rb
  lib/stella/data/http.rb
  lib/stella/engine.rb
  lib/stella/engine/functional.rb
  lib/stella/engine/load_create.rb
  lib/stella/engine/load_em.rb
  lib/stella/engine/load_package.rb
  lib/stella/engine/load_queue.rb
  lib/stella/engine/loadbase.rb
  lib/stella/guidelines.rb
  lib/stella/logger.rb
  lib/stella/testplan.rb
  lib/stella/utils.rb
  lib/stella/utils/httputil.rb
  lib/threadify.rb
  stella.gemspec
  support/sample_webapp/app.rb
  support/sample_webapp/config.ru
  support/useragents.txt
  tryouts/01_numeric_mixins_tryouts.rb
  tryouts/12_digest_tryouts.rb
  tryouts/configs/failed_requests.rb
  tryouts/configs/global_sequential.rb
  tryouts/proofs/thread_queue.rb
  vendor/httpclient-2.1.5.2/httpclient.rb
  vendor/httpclient-2.1.5.2/httpclient/auth.rb
  vendor/httpclient-2.1.5.2/httpclient/cacert.p7s
  vendor/httpclient-2.1.5.2/httpclient/cacert_sha1.p7s
  vendor/httpclient-2.1.5.2/httpclient/connection.rb
  vendor/httpclient-2.1.5.2/httpclient/cookie.rb
  vendor/httpclient-2.1.5.2/httpclient/http.rb
  vendor/httpclient-2.1.5.2/httpclient/session.rb
  vendor/httpclient-2.1.5.2/httpclient/ssl_config.rb
  vendor/httpclient-2.1.5.2/httpclient/timeout.rb
  vendor/httpclient-2.1.5.2/httpclient/util.rb
  )

  
end
