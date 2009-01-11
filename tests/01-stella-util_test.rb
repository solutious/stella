$: << File.dirname(__FILE__)
require 'spec-helper'

#require 'stella/support'


describe "Stella::Util" do
  
  before(:all) do
    load 'stella.rb'
    load 'stella/cli.rb'
    Stella.debug = false
  end
  
  it "knows how to convert ff-3.2-osx and ff,3.2,osx into an array" do
    Stella::Util.expand_str("opera,3.2,linux").should.be.kind_of Array
    Stella::Util.expand_str("ff,3.2,osx").should.equal %w{ff 3.2 osx}
    Stella::Util.expand_str("ie-2-win").should.equal %w{ie 2 win}
  end
  
  it "can read and index the useragents.txt file" do
    ua_index = Stella::Util.process_useragents(File.join(STELLA_HOME, 'support', 'useragents.txt'))
    ua = Stella::Util.find_agent(ua_index, :ff, 3, :linux)
    ua.should.be.kind_of String
    ua.should.match /Firefox\/3/i
    ua.should.match /linux/i
  end
  
  it "can capture STDOUT and STDERR output from a command" do
    command = (Stella::SYSINFO.impl == :windows) ? "dir" : "ls"
    Stella::Util.capture_output("#{command}") do |stdout, stderr|
       stdout.should.be.instance_of Array
       stdout.size.should.be > 0
    end
  end
  
  it "can generate random strings of specified length (29)" do
    str = Stella::Util.strand(29)
    str.should.be.kind_of String
    str.size.should.equal 29
  end
end