$: << File.dirname(__FILE__)
require 'spec-helper'


describe 'Stella' do
  before(:all) do
    require 'stella'
    Stella.debug = false
  end
  
  it "should determine basic system information" do
    
    Stella.sysinfo.should.be.instance_of Stella::SystemInfo
    Stella.sysinfo.uptime.should.be.instance_of Float
    Stella.sysinfo.uptime.should.be > 0
    Stella.sysinfo.hostname.should.be.instance_of String
    Stella.sysinfo.hostname.size.should.be > 0
    Stella.sysinfo.ipaddress.should.be.instance_of String
    Stella.sysinfo.ipaddress.size.should.be > 0
  end
  
  it "should create a working global logger" do
    Stella::LOGGER.should.be.instance_of Stella::Logger
    infos = capture(:stdout) do
      Stella.info("Stella has a kind heart")
    end
    infos.should.be.instance_of String
    infos.chomp.should.equal "Stella has a kind heart"
    
    errors = capture(:stderr) do
      Stella.error("and loves the unexpected!", "ERROR: ")
    end
    errors.should.be.instance_of String
    errors.chomp.should.equal "ERROR: and loves the unexpected!"
  end

  #it "should have at least one language available" do
  #  Stella::TEXT.available_language?('en')
  #end
  
  it "should provide a convenient text interface" do
    Stella.text(:stellaaahhhh).should.equal "Stellaaahhhh!"
  end
  
end


  
#describe 'Options' do
#  include Sinatra::Test
# 
#  before do
#    @app = Class.new(Sinatra::Base)
#  end
# 
#  it 'sets options to literal values' do
#    @app.set(:foo, 'bar')
#    @app.should.respond_to? :foo
#    @app.foo.should.equal 'bar'
#  end
#end

#  it 'includes Rack::Utils' do
#    Sinatra::Base.should.include Rack::Utils
#  end

__END__

TEST-SPEC NOTES

Test/Unit wrappers:

assert_equal:	should.equal, should ==
assert_not_equal:	should.not.equal, should.not ==
assert_same:	should.be
assert_not_same:	should.not.be
assert_nil:	should.be.nil
assert_not_nil:	should.not.be.nil
assert_in_delta:	should.be.close
assert_match:	should.match, should =~
assert_no_match:	should.not.match, should.not =~
assert_instance_of:	should.be.an.instance_of
assert_kind_of:	should.be.a.kind_of
assert_respond_to:	should.respond_to
assert_raise:	should.raise
assert_nothing_raised:	should.not.raise
assert_throws:	should.throw
assert_nothing_thrown:	should.not.throw
assert_block:	should.satisfy

Test/Spec convenience:
* should.not.satisfy
* should.include
* a.should.predicate (works like assert a.predicate?)
* a.should.be operator (where operator is one of >, >=, <, <= or ===)
* should.output (require test/spec/should-output)

Messaging/Blaming:
RUBY_VERSION.should.messaging("Ruby too old.").be > "1.8.4"
(1 + 1).should.blaming("weird math").not.equal 11

Disable tests with xspecify/xit:
When you use xspecify/xit, you also can drop the block

