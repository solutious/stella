# Stella Test Plan - Cookies (2009-10-08)
#
# TO BE DOCUMENTED.
# 
# If you're reading this, remind me!
#
desc "Maintain Your Cookies"

usecase 65, "Simple search" do
  get "/", "Homepage"
  
  get "/search", "Search Results" do
    param :what  => random(['Big', 'Beads'])
    param :where => 'Toronto'
  end
  
  get "/", "Homepage" do
    response 200 do
      puts doc.css('ul#history').first
    end
  end
  
end

# c88c5e4e8c72e305928c8e512ca1e26baf271544
