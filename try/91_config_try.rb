# export trebekpass=''
#Stella.debug=true

class Anonymous
  class FindMonitor < Stella::Usecase

    get '/' do
      response_handler 200 do
        session[:monitor_uri] = doc.css('#headingMonitoring a').first['href'] rescue nil
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
      response_handler 200 do
        session[:shrimp] = (doc.css('#login input[name="shrimp"]').first || {})['value']
      end
    end
    
    post '/login', :follow => true do
      param[:shrimp] = session[:shrimp]
      param[:u] = 'trebek'
      param[:p] = ENV['trebekpass']
    end
    
  end
end

#puts Stella::Testplan.plans[:TestSuite].usecases.first
#h = TestSuite::SimpleUsecase.new.class.instance.to_hash
#c = Stella::Usecase.from_hash h
#p c.requests[2].response_handler.to_hash

@report = Anonymous.checkup "http://www.blamestella.com/"
pp @report.errors.all
