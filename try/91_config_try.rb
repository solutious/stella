Stella.debug=true

class TestSuite
  class SimpleUsecase < Stella::Usecase
    
    get '/' 
    
    get '/login' do
      response_handler 200 do
        session[:shrimp] = body.css['#login input[name="shrimp"]']
      end
    end
    
    post '/login', :follow => true do
      param[:shrimp] = session[:shrimp]
      param[:u] = session[:user]
      param[:p] = session[:pass]
      response_handler 304 do
        session[:redirect_uri] = header[:Location]
      end
    end
    
    get ':redirect_uri' do
      param[:redirect_uri] = session[:redirect_uri]
      response_handler 200 do
        session[:monitor_uri] = body.css('monitors a')
      end
    end
    
    get ':monitor_uri' do
      param[:monitor_uri] = '<%= session[:monitor_uri].random.href %>'
    end
    
  end
end


#puts Stella::Testplan.plans[:TestSuite].usecases.first
#h = TestSuite::SimpleUsecase.new.class.instance.to_hash
#c = Stella::Usecase.from_hash h
#p c.requests[2].response_handler.to_hash

TestSuite.checkup
