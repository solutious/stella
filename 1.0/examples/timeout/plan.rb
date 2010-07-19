# Stella Test Plan - Timeouts (2009-12-08)
#
# TO BE DOCUMENTED. 
# 
# If you're reading this, remind me!
#


usecase "Timeout" do
  timeout 20
  
  get "/" do
    timeout 0.01
  end
  
  get "/"
  
end