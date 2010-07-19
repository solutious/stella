class Testplan
  class SimpleUsecase < Stella::Usecase
    get '/' 
  
    get '/login' do 
      response_handler 200 do
        session[:shrimp] = res.form['#login input[name="shrimp"]']
        check 
      end
    end
  
    post '/login', :follow => false do
      param[:shrimp] = session[:shrimp]
      param[:u] = session[:user]
      param[:p] = session[:pass]
      response_handler 200 do
        session[:shrimp] = res.header[:Location]
      end
    end
    
    get ':redirect_uri' do 
      param[:redirect_uri] = session[:redirect_uri]
      response_handler 200 do
        session[:monitor_uri] = doc.css('monitors a')
      end
    end
    
    get ':monitor_uri' do 
      param[:monitor_uri] = session[:monitor_uri].random.href
    end
    
  end
end

