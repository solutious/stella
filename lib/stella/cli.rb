
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
    uri = Stella.canonical_uri(@argv.first)
    @plan = Stella::Testplan.new uri
    @run = Stella::Testrun.new @plan, :checkup
    @run.options[:repetitions] = @option.repetition
    @run.options[:concurrency] = @option.concurrency
    @report = Stella::Engine.run @run; nil
    metrics = @report.metrics_pack
    unless Stella.quiet?
      case @global.format
      when 'json'
        puts metrics.to_json
      when 'yaml'
        puts metrics.to_yaml
      else
        puts metrics.to_s
      end
    end
    @exit_code = @report.error_count
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
