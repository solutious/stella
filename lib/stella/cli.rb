
class Stella::CLI < Drydock::Command
  attr_accessor :exit_code
  
  def init
    #@conf = Stella::Config.refresh
    @exit_code = 0
  end
  
  def checkup_valid?
    true
  end
  
  
  def checkup
    require 'stella/api'
    base_uri = Stella.canonical_uri(@argv.first)
    run_opts = { 
      :repetitions => @option.repetitions || 1,
      :concurrency => @option.concurrency || 1,
      :wait => @option.wait || 1
    }
    if @option.remote
      @api = Stella::API.new
      ret = @api.post :checkup, :uri => base_uri
      if @api.response.code >= 400
        raise Stella::API::Unauthorized if @api.response.code == 401
        STDERR.puts ret[:msg]
        @exit_code = 1 and return
      end
      begin
        run_hash = @api.get "/checkup/#{ret[:runid]}"
        @run = Stella::Testrun.from_hash run_hash if run_hash
        STDERR.print '.' unless Stella.quiet?
        sleep 1
      end while @run && !@run.done?
      STDERR.puts unless Stella.quiet?
    else
      if @global.testplan
        unless File.owned?(@global.testplan)
          raise ArgumentError, "File not found #{@global.testplan}"
        end
        Stella.ld "Load #{@global.testplan}"
        load @global.testplan
        filter = @global.filter
        planname = Stella::Testplan.plans.keys.first
        @plan = Stella::Testplan.plan(planname)
        if filter
          @plan.usecases.reject! { |uc| 
            ret = !uc.desc.to_s.downcase.match(filter.downcase)
            Stella.ld " rejecting #{uc.desc}" if ret
            ret
          }
        end
        Stella.ld "Running #{@plan.usecases.size} usecases"
      else
        @plan = Stella::Testplan.new base_uri
      end
      @run = @plan.checkup base_uri, run_opts
    end
    
    @report = @run.report
    
    if Stella.quiet?
      @exit_code = @report.error_count
    else
      case @global.format
      when 'csv'
        metrics = @report.metrics_pack
        puts metrics.dump(@global.format)
      when 'json', 'yaml'
        puts @run.dump(@global.format)
      else
        metrics = @report.metrics
        if @global.verbose > 0
          args = ['', '[rt]', '[net]', '[app]', '[d/l]']
          puts "%25s      %6s      %5s     %5s     %5s" % args
        end
        args = [@run.planid.shorten(12), @run.runid.shorten(12),
          metrics.response_time.mean*1000,
          metrics.socket_connect.mean*1000,
          metrics.first_byte.mean*1000,
          metrics.last_byte.mean*1000]
        puts "%s/%s      %6.2fms  (%5.2fms + %5.2fms + %5.2fms)" % args
        #puts @report.metrics_pack.dump(:json)
      end
    end
  rescue Stella::API::Unauthorized => ex
    STDERR.puts "Please check your credentials!"
    STDERR.puts " e.g."
    STDERR.puts "  export STELLA_USER=youraccount"
    STDERR.puts "  export STELLA_KEY=yourapikey"
  end

  def example
    base_path = File.expand_path(File.join(STELLA_LIB_HOME, '..'))
    thin_path = File.join(base_path, 'support', 'sample_webapp', 'config.ru')
    webrick_path = File.join(base_path, 'support', 'sample_webapp', 'app.rb')
    tp_path = File.join(base_path, 'examples', 'essentials', 'plan.rb')
    puts "1. Start the web app:".bright
    puts %Q{
    $ thin -p 3114 -R #{thin_path} start
      OR  
    $ ruby #{webrick_path}
    }
    puts "2. Check the web app in your browser".bright
    puts %Q{
    http://127.0.0.1:3114/
    }
    puts "3. Run a checkup".bright
    puts %Q{
    $ stella checkup -p #{tp_path} 127.0.0.1:3114
    }
  end
  
  private
  
  
  
  
end
