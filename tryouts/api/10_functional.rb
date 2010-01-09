# ruby -Ilib tryouts/api/10_functional.rb
require 'stella'
require 'bone'

Bone['STELLA_TOKEN'] ||= 'c2ea8c27df1c0b968d3d7a98d8402704ff970518'
abort 'Set STELLA_SOURCE' unless Bone['STELLA_SOURCE']

plan_path = File.join STELLA_LIB_HOME, '..', 'examples', 'dynamic', 'plan.rb'
plan = Stella::Testplan.load_file plan_path
puts plan.digest
s = Stella::Service.new Bone['STELLA_SOURCE'], Bone['STELLA_TOKEN']
unless s.testplan? plan.digest
  p :nope
  #tid = s.testplan_create "Testplan 1"
  #s.usecase_create 
end







