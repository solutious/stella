Stella.debug=true

class TestSuite
  class SimpleUsecase < Stella::Usecase
    
    xget '/' 
    
    get '/login', :follow => true do
      response_handler 200 do
        session[:shrimp] = (doc.css('#login input[name="shrimp"]').first || {})['value']
      end
    end
    
    get '/'
    
    xpost '/login', :follow => true do
      param[:shrimp] = session[:shrimp]
      param[:u] = 'trebek' #session[:user]
      param[:p] = '' #session[:pass]
      response_handler 200 do
        puts session.status
        session[:redirect_uri] = header[:Location]
      end
    end
    
    xget ':redirect_uri' do
      param[:redirect_uri] = session[:redirect_uri]
      response_handler 200 do
        session[:monitor_uris] = doc.css('monitors a')
      end
    end
    
    xget ':monitor_uri' do
      param[:monitor_uri] = '<%= session[:monitor_uris].random.href %>'
    end
    
  end
end


#puts Stella::Testplan.plans[:TestSuite].usecases.first
#h = TestSuite::SimpleUsecase.new.class.instance.to_hash
#c = Stella::Usecase.from_hash h
#p c.requests[2].response_handler.to_hash

TestSuite.checkup "http://www.blamestella.com/"
