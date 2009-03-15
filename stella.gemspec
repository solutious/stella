@spec = Gem::Specification.new do |s|
	s.name = "stella"
  s.rubyforge_project = "stella"
	s.version = "0.6.0"
	s.summary = "Your friend in performance testing"
	s.description = s.summary
	s.author = "Delano Mandelbaum"
	s.email = "delano@solutious.com"
	s.homepage = "http://github.com/solutious/stella"
  
  # = DEPENDENCIES =
  # Add all gem dependencies
  #s.add_dependency ''
  
  # = MANIFEST =
  # The complete list of files to be included in the release. When GitHub packages your gem, 
  # it doesn't allow you to run any command that accesses the filesystem. You will get an
  # error. You can ask your VCS for the list of versioned files:
  # git ls-files
  # svn list -R
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.rdoc
  Rakefile
  lib/logger.rb
  lib/slave.rb
  lib/stella.rb
  lib/stella/clients.rb
  lib/stella/command/base.rb
  lib/stella/command/form.rb
  lib/stella/command/get.rb
  lib/stella/common.rb
  lib/stella/crypto.rb
  lib/stella/data/domain.rb
  lib/stella/data/http.rb
  lib/stella/environment.rb
  lib/stella/functest.rb
  lib/stella/loadtest.rb
  lib/stella/stats.rb
  lib/stella/testplan.rb
  lib/stella/testrunner.rb
  lib/storable.rb
  lib/threadify.rb
  lib/timeunits.rb
  lib/util/httputil.rb
  stella.gemspec
  support/fastthread-ruby1.9-one-big-patch.diff
  support/kvm.h
  support/ruby-pcap-takuma-notes.txt
  support/ruby-pcap-takuma-patch.txt
  support/useragents.txt
  tryouts/drb/drb_test.rb
  tryouts/drb/open4.rb
  tryouts/drb/slave.rb
  tryouts/dsl_tryout.rb
  tryouts/oo_tryout.rb
  tryouts/webapp.rb
  vendor/useragent
  
  )
  
  # = EXECUTABLES =
  # The list of executables in your project (if any). Don't include the path, 
  # just the base filename.
  s.executables = %w[stella stella.bat]
  
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt]
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.rdoc"]
  
  s.has_rdoc = true
  s.require_paths = %w[lib]
  s.rubygems_version = '1.1.1'

  
end