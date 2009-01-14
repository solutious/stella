
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
 
  s.name = 'stella'
  s.version = '0.5.5'
  s.date = '2009-01-14'
 
  s.description = "Your friend in performance testing."
  s.summary = "Run Apache Bench, Siege, or httperf tests in batches and aggregate results."
  s.authors = ["Delano Mandelbaum"]
  s.email = ["delano@solutious.com"]
  s.homepage = "http://github.com/solutious/stella"
 
  # = MANIFEST =
  # find {bin,lib,support,vendor} -type f | grep -v git
  s.files = %w(
  README.textile
  CHANGES.txt
  LICENSE.txt
  Rakefile
  bin/stella
  bin/stella.bat
  lib/daemonize.rb
  lib/pcaplet.rb
  lib/stella/adapter/ab.rb
  lib/stella/adapter/base.rb
  lib/stella/adapter/httperf.rb
  lib/stella/adapter/pcap_watcher.rb
  lib/stella/adapter/proxy_watcher.rb
  lib/stella/adapter/siege.rb
  lib/stella/cli/agents.rb
  lib/stella/cli/base.rb
  lib/stella/cli/language.rb
  lib/stella/cli/localtest.rb
  lib/stella/cli/sysinfo.rb
  lib/stella/cli/watch.rb
  lib/stella/cli.rb
  lib/stella/command/base.rb
  lib/stella/command/localtest.rb
  lib/stella/data/domain.rb
  lib/stella/data/http.rb
  lib/stella/logger.rb
  lib/stella/response.rb
  lib/stella/storable.rb
  lib/stella/support.rb
  lib/stella/sysinfo.rb
  lib/stella/test/definition.rb
  lib/stella/test/run/summary.rb
  lib/stella/test/stats.rb
  lib/stella/text/resource.rb
  lib/stella/text.rb
  lib/stella.rb
  lib/utils/crypto-key.rb
  lib/utils/domainutil.rb
  lib/utils/escape.rb
  lib/utils/fileutil.rb
  lib/utils/httputil.rb
  lib/utils/mathutil.rb
  lib/utils/stats.rb
  lib/utils/textgraph.rb
  lib/utils/timerutil.rb
  lib/win32/Console/ANSI.rb
  lib/win32/Console.rb
  support/kvm.h
  support/ruby-pcap-takuma-notes.txt
  support/ruby-pcap-takuma-patch.txt
  support/text/en.yaml
  support/text/nl.yaml
  support/useragents.txt
  vendor/drydock/bin/example
  vendor/drydock/drydock.gemspec
  vendor/drydock/lib/drydock/exceptions.rb
  vendor/drydock/lib/drydock.rb
  vendor/drydock/LICENSE.txt
  vendor/drydock/README.textile
  vendor/drydock/test/command_test.rb
  vendor/useragent/init.rb
  vendor/useragent/lib/user_agent/browsers/all.rb
  vendor/useragent/lib/user_agent/browsers/gecko.rb
  vendor/useragent/lib/user_agent/browsers/internet_explorer.rb
  vendor/useragent/lib/user_agent/browsers/opera.rb
  vendor/useragent/lib/user_agent/browsers/webkit.rb
  vendor/useragent/lib/user_agent/browsers.rb
  vendor/useragent/lib/user_agent/comparable.rb
  vendor/useragent/lib/user_agent/operating_systems.rb
  vendor/useragent/lib/user_agent.rb
  vendor/useragent/MIT-LICENSE
  vendor/useragent/README
  vendor/useragent/spec/browsers/gecko_user_agent_spec.rb
  vendor/useragent/spec/browsers/internet_explorer_user_agent_spec.rb
  vendor/useragent/spec/browsers/opera_user_agent_spec.rb
  vendor/useragent/spec/browsers/other_user_agent_spec.rb
  vendor/useragent/spec/browsers/webkit_user_agent_spec.rb
  vendor/useragent/spec/spec_helper.rb
  vendor/useragent/spec/user_agent_spec.rb
  vendor/useragent/useragent.gemspec
  )
  
  s.test_files = %w(
  tests/01-util_test.rb
  tests/02-stella-util_test.rb
  tests/10-stella_test.rb
  tests/11-stella-storable_test.rb
  tests/60-stella-command_test.rb
  tests/80-stella-cli_test.rb
  tests/spec-helper.rb
  )

  s.extra_rdoc_files = %w[README.textile CHANGES.txt LICENSE.txt]
	s.add_dependency 'net-dns'
	s.add_dependency 'mongrel'
	
  s.has_rdoc = true
  
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Stella", "--main", "README.textile"]
  s.bindir = "bin"
  s.executables = [ "stella", "stella.bat" ]
  s.require_paths = %w[lib vendor]
  s.rubyforge_project = 'stella'
  s.rubygems_version = '1.1.1'
  
end