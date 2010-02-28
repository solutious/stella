
class Stella::CLI < Drydock::Command
  attr_accessor :exit_code
  @template_path = File.join(STELLA_LIB_HOME, 'stella', 'cli')
  class << self
    attr_reader :template_path
  end
  
  def init
  end
  
  require 'pp'
  def run
    raise Stella::Error, "No URIs" if @argv.empty?
    run_opts = [:nowait]  # common options
    case @alias
    when "verify"
      @mode = :functional
    when "generate"
      run_opts.push :clients, :duration, :repetitions, :arrival
      @mode = :load
    when "preview"
      @mode = :preview
    else
      raise Stella::Error, "Unknown mode: #{@alias}"
    end
    
    if @option.testplan
      @testplan = Stella::Testplan.load_file @option.testplan
    end
    
    @testplan.check!  # raise errors, update usecase ratios
    @testplan.freeze  # cascades through usecases and requests
    
    @testrun = Stella::Testrun.new @hosts, @mode, @testplan
    @testrun.desc = @option.msg
    
    run_opts.each do |opt|
      next if @option.send(opt).nil?
      @testrun.send("#{opt}=", @option.send(opt)) 
    end
    
    
    pp @testrun.gibbler
    
    #@exit_code = (ret ? 0 : 1)
  end
  
  # I just don't want to see these
  def example
    @base_path = File.expand_path(File.join(STELLA_LIB_HOME, '..'))
    @thin_path = File.join(@base_path, 'support', 'sample_webapp', 'config.ru')
    @webrick_path = File.join(@base_path, 'support', 'sample_webapp', 'app.rb')
    @tp_path = File.join(@base_path, 'examples', 'essentials', 'plan.rb')
    erb :example
  end
  
  
  private
  def connect_service
    if @global.remote
      #s = Stella::Service.new 
      #Stella::Engine.service = s
    end
  end
  
  def erb(name)
    templ = File.read "#{self.class.template_path}/#{name}.erb"
    t = ERB.new templ
    puts t.result(binding)
  end
  

  
end


module Stella
  class Testplan
    def print_pretty(long=false)
      str = []
      dig = long ? self.digest_cache : self.digest_cache.shorter
      str << " %-66s  ".att(:reverse) % ["#{self.description}  (#{dig})"]
      @usecases.each_with_index do |uc,i| 
        dig = long ? uc.digest_cache : uc.digest_cache.shorter
        desc = uc.description || "Usecase ##{i+1}"
        desc += "  (#{dig}) "
        str << (' ' << " %-61s %s%% ".att(:reverse).bright) % [desc, uc.ratio_pretty]
        unless uc.http_auth.nil?
          str << '    Auth: %s (%s/%s)' % uc.http_auth.values
        end
        requests = uc.requests.each do |r| 
          dig = long ? r.digest_cache : r.digest_cache.shorter
          str << "    %-62s".bright % ["#{r.description}  (#{dig})"]
          str << "      %s" % [r]
          if Stella.stdout.lev > 1
            [:wait].each { |i| str << "      %s: %s" % [i, r.send(i)] }
            str << '       %s: %s' % ['params', r.params.inspect] 
            r.response_handler.each do |status,proc|
              str << "      response: %s%s" % [status, proc.source.split($/).join("#{$/}    ")]
            end
          end
        end
      end
      str.join($/)
    end
  end
end
