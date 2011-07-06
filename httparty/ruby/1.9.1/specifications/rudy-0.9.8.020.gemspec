# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rudy}
  s.version = "0.9.8.020"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2011-02-14}
  s.description = %q{Rudy: Not your grandparents' EC2 deployment tool.}
  s.email = %q{delano@solutious.com}
  s.executables = ["rudy", "rudy-ec2", "rudy-sdb", "rudy-s3"]
  s.extra_rdoc_files = ["README.rdoc", "Rudyfile", "LICENSE.txt", "CHANGES.txt"]
  s.files = ["CHANGES.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "Rudyfile", "UPGRADING-0.9", "bin/rudy", "bin/rudy-ec2", "bin/rudy-s3", "bin/rudy-sdb", "examples/authorize.rb", "examples/gem-test.rb", "examples/solaris.rb", "examples/windows.rb", "lib/rudy.rb", "lib/rudy/aws.rb", "lib/rudy/aws/ec2.rb", "lib/rudy/aws/ec2/address.rb", "lib/rudy/aws/ec2/group.rb", "lib/rudy/aws/ec2/image.rb", "lib/rudy/aws/ec2/instance.rb", "lib/rudy/aws/ec2/keypair.rb", "lib/rudy/aws/ec2/snapshot.rb", "lib/rudy/aws/ec2/volume.rb", "lib/rudy/aws/ec2/zone.rb", "lib/rudy/aws/s3.rb", "lib/rudy/aws/sdb.rb", "lib/rudy/aws/sdb/error.rb", "lib/rudy/backups.rb", "lib/rudy/cli.rb", "lib/rudy/cli/aws/ec2/addresses.rb", "lib/rudy/cli/aws/ec2/candy.rb", "lib/rudy/cli/aws/ec2/groups.rb", "lib/rudy/cli/aws/ec2/images.rb", "lib/rudy/cli/aws/ec2/info.rb", "lib/rudy/cli/aws/ec2/instances.rb", "lib/rudy/cli/aws/ec2/keypairs.rb", "lib/rudy/cli/aws/ec2/snapshots.rb", "lib/rudy/cli/aws/ec2/volumes.rb", "lib/rudy/cli/aws/ec2/zones.rb", "lib/rudy/cli/aws/s3/buckets.rb", "lib/rudy/cli/aws/s3/store.rb", "lib/rudy/cli/aws/sdb/domains.rb", "lib/rudy/cli/aws/sdb/objects.rb", "lib/rudy/cli/aws/sdb/select.rb", "lib/rudy/cli/backups.rb", "lib/rudy/cli/base.rb", "lib/rudy/cli/candy.rb", "lib/rudy/cli/config.rb", "lib/rudy/cli/disks.rb", "lib/rudy/cli/execbase.rb", "lib/rudy/cli/images.rb", "lib/rudy/cli/info.rb", "lib/rudy/cli/keypairs.rb", "lib/rudy/cli/machines.rb", "lib/rudy/cli/metadata.rb", "lib/rudy/cli/networks.rb", "lib/rudy/cli/routines.rb", "lib/rudy/config.rb", "lib/rudy/config/objects.rb", "lib/rudy/disks.rb", "lib/rudy/exceptions.rb", "lib/rudy/global.rb", "lib/rudy/guidelines.rb", "lib/rudy/huxtable.rb", "lib/rudy/machines.rb", "lib/rudy/metadata.rb", "lib/rudy/metadata/backup.rb", "lib/rudy/metadata/disk.rb", "lib/rudy/metadata/machine.rb", "lib/rudy/mixins.rb", "lib/rudy/routines.rb", "lib/rudy/routines/base.rb", "lib/rudy/routines/handlers/base.rb", "lib/rudy/routines/handlers/depends.rb", "lib/rudy/routines/handlers/disks.rb", "lib/rudy/routines/handlers/group.rb", "lib/rudy/routines/handlers/host.rb", "lib/rudy/routines/handlers/keypair.rb", "lib/rudy/routines/handlers/rye.rb", "lib/rudy/routines/handlers/script.rb", "lib/rudy/routines/handlers/user.rb", "lib/rudy/routines/passthrough.rb", "lib/rudy/routines/reboot.rb", "lib/rudy/routines/shutdown.rb", "lib/rudy/routines/startup.rb", "lib/rudy/utils.rb", "rudy.gemspec", "support/mailtest", "support/randomize-root-password", "support/update-ec2-ami-tools", "tryouts/01_mixins/01_hash_tryouts.rb", "tryouts/10_require_time/10_rudy_tryouts.rb", "tryouts/10_require_time/15_global_tryouts.rb", "tryouts/12_config/10_load_config_tryouts.rb", "tryouts/12_config/20_defaults_tryouts.rb", "tryouts/12_config/30_accounts_tryouts.rb", "tryouts/12_config/40_machines_tryouts.rb", "tryouts/12_config/50_commands_tryouts.rb", "tryouts/12_config/60_routines_tryouts.rb", "tryouts/15_huxtable/10_huxtable_tryouts.rb", "tryouts/15_huxtable/20_user_tryouts.rb", "tryouts/20_simpledb/10_domains_tryouts.rb", "tryouts/20_simpledb/20_objects_tryouts.rb", "tryouts/25_ec2/10_keypairs_tryouts.rb", "tryouts/25_ec2/20_groups_tryouts.rb", "tryouts/25_ec2/21_groups_authorize_address_tryouts.rb", "tryouts/25_ec2/22_groups_authorize_account_tryouts.rb", "tryouts/25_ec2/30_addresses_tryouts.rb", "tryouts/25_ec2/40_volumes_tryouts.rb", "tryouts/25_ec2/50_snapshots_tryouts.rb", "tryouts/26_ec2_instances/10_instance_tryouts.rb", "tryouts/26_ec2_instances/50_images_tryouts.rb", "tryouts/30_metadata/10_include_tryouts.rb", "tryouts/30_metadata/13_object_tryouts.rb", "tryouts/30_metadata/50_disk_tryouts.rb", "tryouts/30_metadata/51_disk_digest_tryouts.rb", "tryouts/30_metadata/53_disk_list_tryouts.rb", "tryouts/30_metadata/56_disk_volume_tryouts.rb", "tryouts/30_metadata/60_backup_tryouts.rb", "tryouts/30_metadata/63_backup_list_tryouts.rb", "tryouts/30_metadata/64_backup_disk_tryouts.rb", "tryouts/30_metadata/66_backup_snapshot_tryouts.rb", "tryouts/30_metadata/70_machine_tryouts.rb", "tryouts/30_metadata/73_machine_list_tryouts.rb", "tryouts/30_metadata/76_machine_instance_tryouts.rb", "tryouts/30_metadata/77_machines_tryouts.rb", "tryouts/40_routines/10_keypair_handler_tryouts.rb", "tryouts/40_routines/11_group_handler_tryouts.rb", "tryouts/80_cli/10_rudyec2_tryouts.rb", "tryouts/80_cli/60_rudy_tryouts.rb", "tryouts/exploration/console.rb", "tryouts/exploration/machine.rb", "tryouts/failer"]
  s.homepage = %q{http://solutious.com/projects/rudy/}
  s.rdoc_options = ["--line-numbers", "--title", "Rudy: Not your grandparents' EC2 deployment tool.", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rudy}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Rudy: Not your grandparents' EC2 deployment tool.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rye>, [">= 0.9.3"])
      s.add_runtime_dependency(%q<storable>, [">= 0.8.6"])
      s.add_runtime_dependency(%q<attic>, [">= 0.5.3"])
      s.add_runtime_dependency(%q<annoy>, [">= 0.5.6"])
      s.add_runtime_dependency(%q<drydock>, [">= 0.6.9"])
      s.add_runtime_dependency(%q<caesars>, [">= 0.7.4"])
      s.add_runtime_dependency(%q<sysinfo>, [">= 0.7.3"])
      s.add_runtime_dependency(%q<gibbler>, [">= 0.8.9"])
      s.add_runtime_dependency(%q<aws-s3>, [">= 0.6.1"])
      s.add_runtime_dependency(%q<highline>, [">= 1.5.1"])
      s.add_runtime_dependency(%q<amazon-ec2>, [">= 0.9.10"])
      s.add_development_dependency(%q<tryouts>, [">= 0.8.8"])
    else
      s.add_dependency(%q<rye>, [">= 0.9.3"])
      s.add_dependency(%q<storable>, [">= 0.8.6"])
      s.add_dependency(%q<attic>, [">= 0.5.3"])
      s.add_dependency(%q<annoy>, [">= 0.5.6"])
      s.add_dependency(%q<drydock>, [">= 0.6.9"])
      s.add_dependency(%q<caesars>, [">= 0.7.4"])
      s.add_dependency(%q<sysinfo>, [">= 0.7.3"])
      s.add_dependency(%q<gibbler>, [">= 0.8.9"])
      s.add_dependency(%q<aws-s3>, [">= 0.6.1"])
      s.add_dependency(%q<highline>, [">= 1.5.1"])
      s.add_dependency(%q<amazon-ec2>, [">= 0.9.10"])
      s.add_dependency(%q<tryouts>, [">= 0.8.8"])
    end
  else
    s.add_dependency(%q<rye>, [">= 0.9.3"])
    s.add_dependency(%q<storable>, [">= 0.8.6"])
    s.add_dependency(%q<attic>, [">= 0.5.3"])
    s.add_dependency(%q<annoy>, [">= 0.5.6"])
    s.add_dependency(%q<drydock>, [">= 0.6.9"])
    s.add_dependency(%q<caesars>, [">= 0.7.4"])
    s.add_dependency(%q<sysinfo>, [">= 0.7.3"])
    s.add_dependency(%q<gibbler>, [">= 0.8.9"])
    s.add_dependency(%q<aws-s3>, [">= 0.6.1"])
    s.add_dependency(%q<highline>, [">= 1.5.1"])
    s.add_dependency(%q<amazon-ec2>, [">= 0.9.10"])
    s.add_dependency(%q<tryouts>, [">= 0.8.8"])
  end
end
