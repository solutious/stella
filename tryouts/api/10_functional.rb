# ruby -Ilib tryouts/api/10_functional.rb
require 'stella'
require 'bone'

Stella.enable_debug 

Bone['STELLA_TOKEN'] ||= 'c2ea8c27df1c0b968d3d7a98d8402704ff970518'
abort 'Set STELLA_SOURCE' unless Bone['STELLA_SOURCE']

plan_path = File.join STELLA_LIB_HOME, '..', 'examples', 'dynamic', 'plan.rb'
plan = Stella::Testplan.load_file plan_path
puts plan.digest


service = Stella::Service.new Bone['STELLA_SOURCE'], Bone['STELLA_TOKEN']
unless service.testplan? plan.digest
  puts "Creating Testplan"
  tid = service.testplan_create "Testplan 1", plan.digest
  #s.usecase_create tid
end







