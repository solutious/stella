
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
    base_uri = Stella.canonical_uri(@argv.first)
    run_opts = { 
      :repetitions => @option.repetitions || 1,
      :concurrency => @option.concurrency || 1,
      :wait => @option.wait || 1
    }
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
    @report = @run.report
    if Stella.quiet?
      @exit_code = report.error_count
    else
      @global.format ||= 'json'
      if @global.verbose == 2
        if (@global.format == 'string' || @global.format == 'csv')
          metrics = @report.metrics_pack
          puts metrics.dump(@global.format)
        else 
          puts @report.dump(@global.format)
        end
      elsif @global.verbose >= 3
        puts @run.dump(@global.format)
      end
    end
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
