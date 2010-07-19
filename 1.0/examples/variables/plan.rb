# Stella Test Plan - Using Variables (2009-12-04)
#
#
# 1. START THE EXAMPLE APPLICATION
# 
# This test plan is written to work with the
# example application that ships with Stella. 
# See:
#
# $ stella example
#
# 2. RUN THE TESTPLAN
#
# $ stella --var globalvar=smoked verify -p examples/variables/plan.rb
#
#
usecase "Form Example" do
  set :uri => 'http://localhost:3114'
  set :apple => resource(:globalvar)
  
  # Variables can be used in the request URIs. Stella looks
  # for a replacement value in the usecase resources, then
  # in the params, and then in global variables. 
  get ":uri" do
  end
  
  # URI variables can also be specified with a dollar sign. 
  get "$uri/search" do
    param :what => resource(:globalvar)
    response do
      if resource(:globalvar).nil?
        abort "Usage: stella --var globalvar=smoked verify -p examples/variables/plan.rb"
      end
      puts "  Global variable: " << resource(:globalvar)
      puts "  Usecase variable: " << resource(:uri)
      puts "  Usecase copy of global: " << resource(:apple)
    end
  end
  
end

