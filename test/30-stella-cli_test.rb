$: << File.dirname(__FILE__)
require 'spec-helper'

#require 'stella/cli'

describe "Stella::CLI" do
  
  before(:all) do
    Stella.debug = false
  end
  
  before(:each) do
    ARGV.clear
  end

  it "should auto-require CLI classes" do
    cli_count = Dir.glob(File.join(STELLA_HOME, 'lib', 'stella', 'cli', "*.rb")).size - 1 # Minus base class 
    app = Stella::CLI.new(ARGV, STDIN)
    app.commands.size.should.be >= cli_count  # There can be multiple command aliases per class
  end
  
  xit "should process STDIN"
  
  it "should process global options, command name, and command-specific arguments" do
    ARGV.push *%w{ -vv sysinfo -h --list localhost}
    app = Stella::CLI.new(ARGV, STDIN)
    app.should.be.kind_of Stella::CLI
    app.options.verbose.should.equal 2
    app.command_name.should.equal "sysinfo"
    app.command_arguments.size.should.equal 3
  end
  
  it "should run command and write to STDOUT" do
    ARGV << "lang"
    words = capture(:stdout) do
      app = Stella::CLI.new(ARGV, STDIN)
      app.should.be.kind_of Stella::CLI
      app.command_name.should.equal "lang"
      app.run
    end
    words.should.be.kind_of String
    words.should.match "Available languages"
  end
  
end
