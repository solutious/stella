# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{amazon-ec2}
  s.version = "0.9.17"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Glenn Rempe"]
  s.date = %q{2010-11-21}
  s.description = %q{A Ruby library for accessing the Amazon Web Services EC2, ELB, RDS, Cloudwatch, and Autoscaling APIs.}
  s.email = ["glenn@rempe.us"]
  s.executables = ["awshell", "ec2-gem-example.rb", "ec2-gem-profile.rb", "ec2sh", "setup.rb"]
  s.extra_rdoc_files = ["ChangeLog", "LICENSE", "README.rdoc"]
  s.files = [".gitignore", ".yardopts", "ChangeLog", "Gemfile", "Gemfile.lock", "LICENSE", "README.rdoc", "Rakefile", "VERSION", "amazon-ec2.gemspec", "bin/awshell", "bin/ec2-gem-example.rb", "bin/ec2-gem-profile.rb", "bin/ec2sh", "bin/setup.rb", "deps.rip", "lib/AWS.rb", "lib/AWS/Autoscaling.rb", "lib/AWS/Autoscaling/autoscaling.rb", "lib/AWS/Cloudwatch.rb", "lib/AWS/Cloudwatch/monitoring.rb", "lib/AWS/EC2.rb", "lib/AWS/EC2/availability_zones.rb", "lib/AWS/EC2/console.rb", "lib/AWS/EC2/devpay.rb", "lib/AWS/EC2/elastic_ips.rb", "lib/AWS/EC2/image_attributes.rb", "lib/AWS/EC2/images.rb", "lib/AWS/EC2/instances.rb", "lib/AWS/EC2/keypairs.rb", "lib/AWS/EC2/password.rb", "lib/AWS/EC2/products.rb", "lib/AWS/EC2/security_groups.rb", "lib/AWS/EC2/snapshots.rb", "lib/AWS/EC2/spot_instance_requests.rb", "lib/AWS/EC2/spot_prices.rb", "lib/AWS/EC2/subnets.rb", "lib/AWS/EC2/tags.rb", "lib/AWS/EC2/volumes.rb", "lib/AWS/ELB.rb", "lib/AWS/ELB/load_balancers.rb", "lib/AWS/RDS.rb", "lib/AWS/RDS/rds.rb", "lib/AWS/exceptions.rb", "lib/AWS/responses.rb", "lib/AWS/version.rb", "test/test_Autoscaling_groups.rb", "test/test_EC2.rb", "test/test_EC2_availability_zones.rb", "test/test_EC2_console.rb", "test/test_EC2_elastic_ips.rb", "test/test_EC2_image_attributes.rb", "test/test_EC2_images.rb", "test/test_EC2_instances.rb", "test/test_EC2_keypairs.rb", "test/test_EC2_password.rb", "test/test_EC2_products.rb", "test/test_EC2_responses.rb", "test/test_EC2_s3_xmlsimple.rb", "test/test_EC2_security_groups.rb", "test/test_EC2_snapshots.rb", "test/test_EC2_spot_instance_requests.rb", "test/test_EC2_spot_prices.rb", "test/test_EC2_subnets.rb", "test/test_EC2_volumes.rb", "test/test_ELB_load_balancers.rb", "test/test_RDS.rb", "test/test_helper.rb", "wsdl/2007-08-29.ec2.wsdl", "wsdl/2008-02-01.ec2.wsdl", "wsdl/2008-05-05.ec2.wsdl", "wsdl/2008-12-01.ec2.wsdl", "wsdl/2009-10-31.ec2.wsdl", "wsdl/2009-11-30.ec2.wsdl"]
  s.homepage = %q{http://github.com/grempe/amazon-ec2}
  s.rdoc_options = ["--title", "amazon-ec2 documentation", "--line-numbers", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{amazon-ec2}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Amazon EC2 Ruby gem}
  s.test_files = ["test/test_Autoscaling_groups.rb", "test/test_EC2.rb", "test/test_EC2_availability_zones.rb", "test/test_EC2_console.rb", "test/test_EC2_elastic_ips.rb", "test/test_EC2_image_attributes.rb", "test/test_EC2_images.rb", "test/test_EC2_instances.rb", "test/test_EC2_keypairs.rb", "test/test_EC2_password.rb", "test/test_EC2_products.rb", "test/test_EC2_responses.rb", "test/test_EC2_s3_xmlsimple.rb", "test/test_EC2_security_groups.rb", "test/test_EC2_snapshots.rb", "test/test_EC2_spot_instance_requests.rb", "test/test_EC2_spot_prices.rb", "test/test_EC2_subnets.rb", "test/test_EC2_volumes.rb", "test/test_ELB_load_balancers.rb", "test/test_RDS.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<xml-simple>, [">= 1.0.12"])
      s.add_development_dependency(%q<mocha>, [">= 0.9.9"])
      s.add_development_dependency(%q<test-spec>, [">= 0.10.0"])
      s.add_development_dependency(%q<rcov>, [">= 0.9.9"])
      s.add_development_dependency(%q<perftools.rb>, [">= 0.5.4"])
      s.add_development_dependency(%q<yard>, [">= 0.6.2"])
    else
      s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
      s.add_dependency(%q<mocha>, [">= 0.9.9"])
      s.add_dependency(%q<test-spec>, [">= 0.10.0"])
      s.add_dependency(%q<rcov>, [">= 0.9.9"])
      s.add_dependency(%q<perftools.rb>, [">= 0.5.4"])
      s.add_dependency(%q<yard>, [">= 0.6.2"])
    end
  else
    s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
    s.add_dependency(%q<mocha>, [">= 0.9.9"])
    s.add_dependency(%q<test-spec>, [">= 0.10.0"])
    s.add_dependency(%q<rcov>, [">= 0.9.9"])
    s.add_dependency(%q<perftools.rb>, [">= 0.5.4"])
    s.add_dependency(%q<yard>, [">= 0.6.2"])
  end
end
