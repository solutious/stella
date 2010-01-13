# ruby -Ilib tryouts/api/10_functional.rb
require 'stella'
require 'bone'

Stella.enable_debug 

Bone['STELLA_TOKEN'] = '1'.gibbler
abort 'Set STELLA_SOURCE' unless Bone['STELLA_SOURCE']

plan_path = File.join STELLA_LIB_HOME, '..', 'examples', 'essentials', 'plan.rb'
plan = Stella::Testplan.load_file plan_path

service = Stella::Service.new Bone['STELLA_SOURCE'], Bone['STELLA_TOKEN']
service.testplan_sync plan

service.testrun_create :hosts => ['http://locahost:3000', 'http://locahost:3001']




