# ruby -Ilib tryouts/29_from_json.rb

require 'stella'

#Stella.enable_debug

#Gibbler.enable_debug

json1 = DATA.read
run1 = Stella::Testrun.from_json(json1)

#run1.plan.usecases.first.requests.first.response 200 do
#  puts "hey hey!"
#end

run1.plan.usecases.first.requests.first.response_handler.each_pair do |status,block|
  puts block.source  # should print "hey hey!"
end

json2 = run1.to_json
run2 = Stella::Testrun.from_json(json2)
run2.plan.usecases.first.requests.first.response_handler.each_pair do |status,block|
  puts block.source  # should print "hey hey!"
end

p [run1.id, run1.plan.id, run1.plan.usecases.first.id]
p [run2.id, run2.plan.id, run2.plan.usecases.first.id]


__END__
{"samples":[],"clients":1,"duration":null,"arrival":null,"repetitions":1,"nowait":false,"withparam":null,"withheader":null,"notemplates":null,"nostats":null,"start_time":null,"mode":"generate","plan":{"id":"89edb1b36f3637965a856765c99c6392125beba5","usecases":[{"id":"90d02c765c98879b5df5cf36497e9a5eb1c9a58f","description":null,"ratio":1.0,"http_auth":null,"timeout":null,"requests":[{"id":"ef37671f4f9bd593b3bdac53000bdda6a4abe713","description":"Request","header":{},"uri":"http:\/\/localhost:3114\/search?what=t&where=tor","wait":0,"params":{},"body":null,"http_method":"GET","http_version":"1.1","content_type":null,"http_auth":null,"timeout":null,"autofollow":false,"response_handler":{}}],"resources":{}}],"description":"Test plan"},"stats":{"summary":{"response_time":{"min":0.0,"mean":0.0,"max":0.0,"sd":0.0,"n":0.0,"sum":0.0,"sumsq":0.0},"failed":{"min":0.0,"mean":0.0,"max":0.0,"sd":0.0,"n":0.0,"sum":0.0,"sumsq":0.0}},"90d02c765c98879b5df5cf36497e9a5eb1c9a58f":{"summary":{"response_time":{"min":0.0,"mean":0.0,"max":0.0,"sd":0.0,"n":0.0,"sum":0.0,"sumsq":0.0},"failed":{"min":0.0,"mean":0.0,"max":0.0,"sd":0.0,"n":0.0,"sum":0.0,"sumsq":0.0}},"ef37671f4f9bd593b3bdac53000bdda6a4abe713":{"response_time":{"min":0.0,"mean":0.0,"max":0.0,"sd":0.0,"n":0.0,"sum":0.0,"sumsq":0.0},"failed":{"min":0.0,"mean":0.0,"max":0.0,"sd":0.0,"n":0.0,"sum":0.0,"sumsq":0.0}}}},"hosts":[""],"events":["response_time","failed"],"log":null}