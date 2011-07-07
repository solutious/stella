
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
    # NOTE ABOUT CLI OUTPUT:
    # Output when a testplan is supplied comes from Engine.run
    # while it's being executed. Otherwise it's generated from
    # testrun.report after the generic testplan has run.
    if @global.format || !@global.testplan
      Stella.noise = 0 
    end
    @global.remote ||= @global.account || @global.key
    if @global.remote
      raise "Running a testplan remotely isn't supported yet (soon!)" if @global.testplan
      @api = Stella::API.new @global.account, @global.key
      ret = @api.post :checkup, :uri => base_uri
      if ret && ret[:runid]
        shortid = ret[:runid].slice  0, 19
        @more_info = @api.site_uri "/checkup/#{shortid}"
      end
      pp @api.response if Stella.debug
      if @api.response.code >= 400
        raise Stella::API::Unauthorized if @api.response.code == 401
        STDERR.puts ret[:msg]
        @exit_code = 1 and return
      end
      begin
        run_hash = @api.get "/checkup/#{ret[:runid]}"
        @run = Stella::Testrun.from_hash run_hash if run_hash
        STDERR.print '.' if @global.verbose > 0
        sleep 1 if @run && !@run.done?
      end while @run && !@run.done?
      STDERR.puts if @global.verbose > 0
    else
      if @global.testplan
        unless File.owned?(@global.testplan)
          raise ArgumentError, "File not found #{@global.testplan}"
        end
        Stella.ld "Load #{@global.testplan}"
        load @global.testplan
        filter = @global.usecase
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
    
    @exit_code = @report.error_count if Stella.quiet?
    
    unless @global.testplan
      case @global.format
      when 'csv'
        metrics = @report.metrics_pack
        puts metrics.dump(@global.format)
      when 'json', 'yaml'
        puts @run.dump(@global.format)
      else
        if @global.verbose > 0 || @report.errors?
          test_uri = @report.log.first ? @report.log.first.uri : '[unknown]'
          Stella.li 'Checkup for %s' % [test_uri]
          Stella.li
          Stella.li '  %s' % [@report.headers.request_headers.split(/\n/).join("\n  ")]
          Stella.li
          Stella.li '  %s' % [@report.headers.response_headers.split(/\n/).join("\n  ")]
          Stella.li ''
        end
        metrics = @report.metrics
        args = [@report.statuses.values.first,
          metrics.response_time.mean*1000,
          metrics.socket_connect.mean*1000,
          metrics.first_byte.mean*1000,
          metrics.last_byte.mean*1000,
          @more_info]
        Stella.li "[%3s] %7.2fms (%5.2fms + %6.2fms + %6.2fms)  %s" % args
      end
    end
  rescue Stella::API::Unauthorized => ex
    accnt = @api.account || 'youraccount'
    key = @api.key || 'yourapikey'
    STDERR.puts "Specify your credentials"
    STDERR.puts "  export STELLA_ACCOUNT=#{accnt}"
    STDERR.puts "  export STELLA_KEY=#{key}"
    STDERR.puts " OR "
    STDERR.puts "  stella -A #{accnt} -K #{key} checkup #{@argv.first}"
    STDERR.puts 
    STDERR.puts "Create an account, at no charge!"
    STDERR.puts "https://www.blamestella.com/signup/free"
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
