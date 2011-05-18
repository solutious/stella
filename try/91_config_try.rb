# export trebekpass=''
#Stella.debug=true
# ruby -Ilib -rstella try/91_config_try.rb

class DefaultExample < Stella::Usecase
  get ':anything'
end

module Anonymous
  class FindMonitor < Stella::Usecase
    http_auth :delano, 'token'
    
    get '/' do
      response 200 do
        session[:monitor_uri] = doc.css('#headingMonitoring a').first['href']
        raise Stella::PageError, "No value for :monitor_uri" if session[:monitor_uri].to_s.empty?
      end
    end
    
    get ':monitor_uri'
    
  end
end

class Authorized
  class Login < Stella::Usecase
    
    get '/' 
    
    get '/login', :follow => true do
      response 200 do
        session[:shrimp] = (doc.css('#login input[name="shrimp"]').first || {})['value']
      end
    end
    
    post '/login' do
      param[:shrimp] = session[:shrimp]
      param[:u] = 'trebek'
      param[:p] = ENV['trebekpass']
      response 300..399 do
        raise Stella::ForcedRedirect, session.location
      end
    end
    
  end
end

#p Stella::Testplan.plan?(DefaultTestplan)  # created by DefaultExample above.

puts Anonymous.testplan.to_yaml
puts Anonymous.checkup('http://bs.com:3000/').to_yaml

#@report = Anonymous.checkup "http://www.blamestella.com/"
#pp @report.errors.all if @report.errors?

#@report = Authorized.checkup "http://www.blamestella.com/"
#if @report.errors?
#  puts  @report.errors.all 
#else
#  puts @report.metrics_pretty
#  puts
#  puts @report.statuses_pretty
#end
